-- Erstelle ein neues Addon mit dem Namen "LastLearned"
local ADDON_NAME = "LastLearned"
local ADDON_VERSION = "1.0"

-- Erstelle eine Tabelle für das Addon und füge die benötigten Libraries hinzu
local LastLearned = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local LibDBIcon = LibStub("LibDBIcon-1.0")

-- Funktion zum Anzeigen des Logfensters
local function ShowLogWindow()
    if not LastLearned.LogWindow then
        LastLearned.LogWindow = AceGUI:Create("Frame")
        LastLearned.LogWindow:SetTitle("Last Learned - Abilities and Talents")
        LastLearned.LogWindow:SetWidth(480)
        LastLearned.LogWindow:SetHeight(400)
        LastLearned.LogWindow:SetLayout("Flow")

        -- Erstelle eine Scrollframe für die Anzeige der Logdaten
        local scrollFrame = AceGUI:Create("ScrollFrame")
        scrollFrame:SetLayout("Flow")
        scrollFrame:SetFullWidth(true)
        scrollFrame:SetHeight(260)
        LastLearned.LogWindow:AddChild(scrollFrame)

        -- Erstelle ein Label für den Counter
        local counterLabel = AceGUI:Create("Label")
        counterLabel:SetText("Rolls used: 0")
        counterLabel:SetWidth(200)
        scrollFrame:AddChild(counterLabel)
		
		local rlbar = AceGUI:Create("SimpleGroup")
		rlbar:SetLayout("Flow")
		rlbar:SetFullWidth(true)
		LastLearned.LogWindow:AddChild(rlbar)
		
			-- Create a button for UI reload
			local reloadButton = AceGUI:Create("Button")
			reloadButton:SetText("Reload UI")
			reloadButton:SetRelativeWidth(0.2)
			reloadButton:SetCallback("OnClick", function()
				ReloadUI()
			end)
			rlbar:AddChild(reloadButton)

			-- Erstelle ein Label für den Reload-Button
			local rlLabel = AceGUI:Create("Label")
			rlLabel:SetText("To display the history you have to reload the UI after using your scrolls.")
			rlLabel:SetRelativeWidth(0.8)
			rlbar:AddChild(rlLabel)
			
		local exportBar = AceGUI:Create("SimpleGroup")
		exportBar:SetLayout("Flow")
		exportBar:SetFullWidth(true)
		LastLearned.LogWindow:AddChild(exportBar)
		
			-- Create a button for Export Data
			local exportButton = AceGUI:Create("Button")
			exportButton:SetText("Export Data")
			exportButton:SetRelativeWidth(0.2)
			exportButton:SetCallback("OnClick", function()
				ShowExportableDataWindow()
			end)
			exportBar:AddChild(exportButton)

			-- Erstelle ein Label für den Export-Button
			local exportLabel = AceGUI:Create("Label")
			exportLabel:SetText("To export your data to an Excel spreadsheet. Separator semicolon ( ; )")
			exportLabel:SetRelativeWidth(0.8)
			exportBar:AddChild(exportLabel)

        -- Fülle die Logdatei mit vorhandenen Daten
        local savedData = LastLearned:GetSavedData()
        if savedData then
            local header = AceGUI:Create("SimpleGroup")
            header:SetLayout("Flow")
            header:SetFullWidth(true)
            local talentHeaderLabel = AceGUI:Create("Label")
            talentHeaderLabel:SetText("Talent")
            talentHeaderLabel:SetRelativeWidth(0.5)
            local spellHeaderLabel = AceGUI:Create("Label")
            spellHeaderLabel:SetText("Spell")
            spellHeaderLabel:SetRelativeWidth(0.5)
            header:AddChild(talentHeaderLabel)
            header:AddChild(spellHeaderLabel)
            scrollFrame:AddChild(header)

            for _, data in ipairs(savedData) do
                local row = AceGUI:Create("SimpleGroup")
                row:SetLayout("Flow")
                row:SetFullWidth(true)
                local talentLabel = AceGUI:Create("Label")
                talentLabel:SetText(data.talentName or "")
                talentLabel:SetRelativeWidth(0.5)
                local spellLabel = AceGUI:Create("Label")
                spellLabel:SetText(data.spellName or "")
                spellLabel:SetRelativeWidth(0.5)
                row:AddChild(talentLabel)
                row:AddChild(spellLabel)
                scrollFrame:AddChild(row)
            end
            counterLabel:SetText("Scrolls used: " .. #savedData)
        end
    end
    LastLearned.LogWindow:Show()
end

-- Funktion zum Verarbeiten von Chatnachrichten
function LastLearned:ProcessChatMessage(event, message)
    local talentName = string.match(message, "You have learned a new talent: (.+)")
    local spellName = string.match(message, "You have learned a new spell: (.+)")
    if talentName then
        self:SaveData(nil, talentName)
        if self.LogWindow and self.LogWindow:IsVisible() then
            ShowLogWindow()
        end
    elseif spellName then
        -- Extrahiere die Spell-ID aus der Chatnachricht
        local spellID = string.match(message, "spell:(%d+)")
        if spellID then
            local _, _, _, _, _, _, spellLink = GetSpellInfo(spellID)
            if spellLink then
                self:SaveData(spellName, nil, spellLink)
                if self.LogWindow and self.LogWindow:IsVisible() then
                    ShowLogWindow()
                end
            else
                print("Unable to create spell link for spell: " .. spellName)
            end
        else
            print("Unable to find spell ID for spell: " .. spellName)
        end
    end
end

-- Registriere das Ereignis für den Chat
function LastLearned:OnInitialize()

    -- Erstelle die Datenbank für die SavedVariables
    self.db = LibStub("AceDB-3.0"):New("LastLearnedDB", {
        char = {
            learnedAbilities = {},
            rollsUsed = 0, -- Counter für erlernte Fähigkeiten und Talente
            minimapIcon = {}, -- Initialisiere das minimapIcon-Feld
        },
    }, true)

    -- Registriere das Ereignis für den Chat
    self:RegisterEvent("CHAT_MSG_SYSTEM", "ProcessChatMessage")

-- Registriere den Chat-Befehl "/ll" zum Anzeigen des Logfensters
SlashCmdList["LASTLEARNED"] = ShowLogWindow
SLASH_LASTLEARNED1 = "/ll"

    
    -- Registriere den Chat-Befehl "/lldelete" zum Löschen des Logs
    self:RegisterChatCommand("lldelete", "DeleteLog")

    -- Füge das Minimap-Icon hinzu
    self.minimapIcon = {
        icon = "Interface\\Addons\\LastLearned\\LastLearned_Icon",
        OnClick = function(self, button)
            if button == "LeftButton" then
                ShowLogWindow()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:SetText("Last Learned")
            tooltip:AddLine(" ")
            tooltip:AddLine("|cff6699FFClick|r to open Last Learned")
            tooltip:AddLine("|cff6699FF/ll|r to open Last Learned")
            tooltip:AddLine("|cff6699FF/lldelete|r to clear the Last Learned")
        end,
    }
    LibDBIcon:Register("LastLearnedIcon", self.minimapIcon, self.db.char.minimapIcon)
end

-- Funktion zum Löschen des Logs
function LastLearned:DeleteLog()
    -- Öffne ein Bestätigungsfenster
    StaticPopupDialogs["CONFIRM_DELETE_LOG"] = {
        text = "Are you sure you want to delete the history of this character for all previously learned skills, talents and casts?",
        button1 = "Yes",
        button2 = "Nno",
        OnAccept = function()
            -- Lösche den Log
            self.db.char.learnedAbilities = {}
            print("Data history deleted")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3, -- Vermeide einige UI-Verschmutzungen
    }
    StaticPopup_Show("CONFIRM_DELETE_LOG")
end

-- Funktion zum Speichern von Daten in die SavedVariables
function LastLearned:SaveData(spellName, talentName, spellLink)
    if not self.db.char.learnedAbilities then
        self.db.char.learnedAbilities = {}
    end
    table.insert(self.db.char.learnedAbilities, { spellName = spellName, talentName = talentName, spellLink = spellLink })
end

-- Funktion zum Laden von gespeicherten Daten aus den SavedVariables
function LastLearned:GetSavedData()
    if self.db.char.learnedAbilities then
        return self.db.char.learnedAbilities
    else
        return nil
    end
end

-- Funktion zum Öffnen des Fensters mit den formatierten Daten für den Export
function ShowExportableDataWindow()
    if not LastLearned.ExportableDataWindow then
        LastLearned.ExportableDataWindow = AceGUI:Create("Frame")
        LastLearned.ExportableDataWindow:SetTitle("Exportable Data - Spell and Talent Names")
        LastLearned.ExportableDataWindow:SetWidth(450)
        LastLearned.ExportableDataWindow:SetHeight(300)
        LastLearned.ExportableDataWindow:SetLayout("Flow")

        -- Erstelle eine Scrollframe für die Anzeige der formatierten Daten
        local scrollFrame = AceGUI:Create("ScrollFrame")
        scrollFrame:SetLayout("Flow")
        scrollFrame:SetFullWidth(true)
        scrollFrame:SetHeight(200)
        LastLearned.ExportableDataWindow:AddChild(scrollFrame)

        -- Fülle die formatierten Daten aus den SavedVariables
        local savedData = LastLearned:GetSavedData()
        if savedData then
            -- Erstelle den Text für den Export
            local exportText = "Character Name;" .. "Used Scrolls: " .. #savedData .. "\n"
            exportText = exportText .. UnitName("player") .. ";" .. #savedData .. "\n"
            exportText = exportText .. "Talent Name;Spell Name\n"

            -- Füge die Daten in das Export-Textfeld ein
            for _, data in ipairs(savedData) do
                exportText = exportText .. (data.talentName or "") .. ";" .. (data.spellName or "") .. "\n"
            end

            -- Erstelle ein Label für das Export-Textfeld
            local exportLabel = AceGUI:Create("MultiLineEditBox")
            exportLabel:SetText(exportText)
            exportLabel:SetFullWidth(true)
            exportLabel:SetNumLines(10)
            scrollFrame:AddChild(exportLabel)
        end
    end
    LastLearned.ExportableDataWindow:Show()
end
