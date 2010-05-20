-- SaitoHUD
-- Copyright (c) 2009-2010 sk89q <http://www.sk89q.com>
-- Copyright (c) 2010 BoJaN
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 2 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- $Id$

-- Panel GUI.

local pointsList
local quickFilters = {}

--- Loads the quick filters from file.
local function LoadQuickFilters()
    local data = SaitoHUD.ParseCSV(file.Read("saitohud/quick_filters.txt"))
    
    if #data > 0 then
        -- Remove the header
        if data[1][1] == "Filter" then
            table.remove(data, 1)
        end
        
        quickFilters = {""}
        
        for _, v in pairs(data) do
            if v[1] and v[1] ~= "" then
                table.insert(quickFilters, v[1])
            end
        end
    else
        quickFilters = {
            "",
            "pod",
            "npc",
            "vehicle",
            "sent_ball",
            "maxdist=1000 and prop",
            "wire_expr",
        }
    end
end

--- Adds an input to a panel.
-- @param panel
-- @param text
-- @param command
-- @param clearOnEnter
-- @param unfair True if function is disabled in cheat deterrence mode
-- @return Control
local function AddInput(panel,  text, command, clearOnEnter, unfair)
    panel:AddControl("Label", {Text = text})
    
    local entry = panel:AddControl("DTextEntry", {})
    entry:SetTall(20)
    entry:SetWide(100)
    entry:SetEnterAllowed(true)
    entry.OnEnter = function()
        LocalPlayer():ConCommand(command .. " " .. entry:GetValue())
        if clearOnEnter then
            entry:SetValue("")
        end
    end
    
    if unfair then
        entry:SetEditable(not SaitoHUD.AntiUnfairTriggered())
        entry:SetDrawBackground(not SaitoHUD.AntiUnfairTriggered())
    end
    
    return entry
end

--- Adds a label to a panel.
-- @param panel
-- @param text
-- @return Control
local function AddLabel(panel, text)
	panel:AddControl("Label", {Text=text})
end

--- Adds a checkbox to a panel.
-- @param panel
-- @param text
-- @param command
-- @param unfair True if function is disabled in cheat deterrence mode
-- @return Control
local function AddToggle(panel, text, command, unfair)
    local c = panel:AddControl("CheckBox", {
        Label = text,
        Command = command
    })
    
    if unfair then
        c:SetDisabled(SaitoHUD.AntiUnfairTriggered())
    end
    return c
end

--- Adds a button to a panel.
-- @param panel
-- @param text
-- @param command
-- @return Control
local function AddButton(panel, label, command)
    local button
    
    if type(command) == "function" then
        button = panel:AddControl("DButton", {})
        button:SetText(label)
        button.DoClick = command
    else
        button = panel:AddControl("Button", {
            Label = label,
            Command = command
        })
    end
		
	if unfair then
		button:SetDisabled(SaitoHUD.AntiUnfairTriggered())
	end
    
	return button
end

--- Adds the quick filter list for the filtering panel.
-- @param panel
-- @param cmd
-- @param text
-- @param input
-- @return
local function AddQuickFilterList(panel, cmd, text, field)
	local ctrl = panel:AddControl("DListView", {})
    ctrl:AddColumn("Quick " .. text .. " Filter")
    ctrl:SetTall(101)
    
    ctrl.OnRowSelected = function(panel, line) 
        local args = SaitoHUD.ParseCommand(panel:GetLine(line):GetValue(1))
        RunConsoleCommand(cmd, unpack(args))
    end
    
    ctrl.OnRowRightClick = function(lst, index, line)
        local menu = DermaMenu()
        menu:AddOption("Set Input to Value", function()
            field:SetValue(line:GetValue(1))
        end)
        menu:AddOption("Copy", function()
            SetClipboardText(line:GetValue(1))
        end)
        menu:Open()
    end
    
    for _, filter in pairs(quickFilters) do
        ctrl:AddLine(filter) 
    end
end

--- Creates the help panel.
-- @param panel
local function HelpPanel(panel)
    panel:ClearControls()
    panel:AddHeader()
    
    local button = panel:AddControl("DButton", {})
    button:SetText("Help")
    button.DoClick = function(button)
        SaitoHUD.OpenHelp()
    end
end

--- Creates the tools panel.
-- @param panel
local function ToolPanel(panel)
    panel:ClearControls()
    panel:AddHeader()
    
    local button = panel:AddControl("DButton", {})
    button:SetText("Sound Browser")
    button.DoClick = function(button)
        SaitoHUD.OpenSoundBrowser()
    end
end

--- Creates the sampling panel.
-- @param panel
local function SamplingPanel(panel)
    panel:ClearControls()
    panel:AddHeader()
    
    if SaitoHUD.AntiUnfairTriggered() then
        panel:AddControl("Label", {Text = "WARNING: A non-sandbox game mode has been detected and the following options do not take effect."})
    end
    
    AddButton(panel, "Sample Entity", "sample", false)
    AddButton(panel, "Clear", "sample_clear", false)
    
    AddToggle(panel, "Draw Sampled Data", "sample_draw", true)
    AddToggle(panel, "Draw Nodes", "sample_nodes", false)
    AddToggle(panel, "Draw Thick Lines", "sample_thick", false)
    AddToggle(panel, "Fade Samples", "sample_fade", false)
    AddToggle(panel, "Use Random Colors", "sample_random_color", false)
    AddToggle(panel, "Allow Multiple", "sample_multiple", false)
    
    panel:AddControl("Slider", {
        Label = "Resolution (ms):",
        Command = "sample_resolution",
        Type = "integer",
        min = "1",
        max = "500"
    })
    
    panel:AddControl("Slider", {
        Label = "Data Point History Size:",
        Command = "sample_size",
        Type = "integer",
        min = "1",
        max = "500"
    })
    
    AddInput(panel, "Sample Player by Name:", "sample", true, true)
        :SetToolTip("Partial names accepted")
    AddInput(panel, "Remove Player by Name:", "sample_remove", true, true)
        :SetToolTip("Partial names accepted")
    AddInput(panel, "Sample by Filter:", "sample_filter", true, true)
        :SetToolTip("Enter a filter and then press ENTER")
    AddInput(panel, "Remove by Filter:", "sample_remove_filter", true, true)
        :SetToolTip("Enter a filter and then press ENTER")
end

--- Creates the overlay panel.
-- @param panel
local function OverlayPanel(panel)
    panel:ClearControls()
    panel:AddHeader()
    
	AddLabel(panel, "Entity Information:")
    AddToggle(panel, "Show Entity Information", "entity_info", 0)
    AddToggle(panel, "Show Player Info on Entity Information", "entity_info_player",0)
    
    if SaitoHUD.AntiUnfairTriggered() then
        panel:AddControl("Label", {Text = "WARNING: A non-sandbox game mode has been detected and the following options do not take effect."})
    end
    
	AddLabel(panel, "Name Tags:")
    AddToggle(panel, "Show Name Tags", "name_tags", true)
    AddToggle(panel, "Always Show Friends", "friend_tags_always", true)
        :SetToolTip("See the help to find out how to define a friends list")
    AddToggle(panel, "Simple Text Style", "name_tags_simple", true)
    AddToggle(panel, "Show Distance", "name_tags_distances", true)
    AddToggle(panel, "Rainbow Friends' Names", "name_tags_rainbow_friends", true)
    AddToggle(panel, "Bold Friends' Names", "name_tags_bold_friends", true)
	
	AddLabel(panel, "Players:")
    AddToggle(panel, "Show Player Bounding Boxes", "player_boxes", true)
    AddToggle(panel, "Show Player Orientation Markers", "player_markers", true)
    AddToggle(panel, "Show Player Line of Sights", "trace_aims", true)
end

--- Creates the filtering panel.
-- @param panel
local function EntityHighlightingPanel(panel)
    panel:ClearControls()
    panel:AddHeader()
    
    AddToggle(panel, "Continuous Filter Evaluation", "overlays_continuous_eval", false)
    
    -- Triads filter
    
    local ctrl = AddInput(panel, "Triads Filter:", "triads_filter", false, true)
    ctrl:SetToolTip("Enter a filter and then press ENTER")
    
	AddQuickFilterList(panel, "triads_filter", "Triads", ctrl)
    
    -- Overlay filter
    
    local ctrl = AddInput(panel, "Overlay Filter:", "overlay_filter", false, true)
    ctrl:SetToolTip("Enter a filter and then press ENTER")
    
	AddQuickFilterList(panel, "overlay_filter", "Overlay", ctrl)
    
	panel:AddControl("ListBox", {
        Label = "Overlay Filter Text",
        MenuButton = false,
        Height = 52,
        Options = {
            Class = {overlay_filter_text = "class"},
            Model = {overlay_filter_text = "model"},
            Material = {overlay_filter_text = "material"},
            Speed = {overlay_filter_text = "speed"},
            ["Peak Speed"] = {overlay_filter_text = "peakspeed"},
        }
    })
	
	AddLabel(panel, "Peak speed evaluation benefits from continuous filter evaluation if accuracy is desired.")
    
    AddToggle(panel, "Print Cached Data on Entity Removal", "overlay_filter_print_removed", false)
    AddButton(panel, "Clear Cache", "overlay_filter_clear_cache", false)
    
    -- Bounding box filter
    
    local ctrl = AddInput(panel, "Bounding Box Filter:", "bbox_filter", false, true)
    ctrl:SetToolTip("Enter a filter and then press ENTER")
    
	AddQuickFilterList(panel, "bbox_filter", "Bounding Box", ctrl)
end

--- Creates the surveying panel.
-- @param panel
local function SurveyPanel(panel)
    panel:ClearControls()
    panel:AddHeader()
    
	AddLabel(panel, "Orthogonal Tracing:")
    AddButton(panel, "Create Orthogonal Line", "ortho_trace", false)
    AddButton(panel, "Clear", "ortho_trace_clear", false)
    AddToggle(panel, "Show Trace Text", "ortho_trace_text", true)
    
    -- Reflection analysis
	
	AddLabel(panel, "Reflection Analysis:")
    
	panel:AddControl("ListBox", {
        Label = "Do Trace with # Bounces",
        MenuButton = false,
        Height = 102,
        Options = {
            ["10"] = {reflect_trace = 5},
            ["25"] = {reflect_trace = 25},
            ["50"] = {reflect_trace = 50},
            ["100"] = {reflect_trace = 100},
            ["250"] = {reflect_trace = 250},
            ["500"] = {reflect_trace = 500},
            ["750"] = {reflect_trace = 750},
            ["1000"] = {reflect_trace = 1000}
        }
    })
    AddButton(panel, "Clear", "reflect_trace_clear", false)
    
    AddToggle(panel, "Show Nodes", "reflect_trace_nodes", true)
    AddToggle(panel, "Allow Multiple", "reflect_trace_multiple", true)
    AddToggle(panel, "Color Progression", "reflect_trace_color_progression", true)
end

--- Creates the measuring panel.
-- @param panel
local function MeasuringPanel(panel)
    panel:ClearControls()
    panel:AddHeader()
    
    AddButton(panel, "Add Point", "measure_add", false)
    AddButton(panel, "Add Point by Coordinate", function()
        Derma_StringRequest("Add Point",
                            "Enter X, Y, and Z, separated by commas:",
                            "",
                            function(text)
                                text = text:Trim()
                                if text:match("[%-0-9%.]+,? [%-0-9%.]+,? [%-0-9%.]+") then
                                    args = string.Explode(" ", text)
                                    RunConsoleCommand("measure_add", unpack(args))
                                end
                            end)
    end, false)
    AddButton(panel, "Add Orthogonal Line", "measure_add_ortho", false)
    AddButton(panel, "Close Loop", "measure_close", false)
    AddButton(panel, "Delete Last Point", "measure_remove_last", false)
    AddButton(panel, "Clear", "measure_clear", false)
    
    pointsList = panel:AddControl("DListView", {})
    pointsList:SetMultiSelect(false)
    pointsList:AddColumn("ID"):SetMaxWidth(30)
    pointsList:AddColumn("Position")
    pointsList:SetTall(300)
    
    for k, pt in pairs(SaitoHUD.MeasurePoints) do
        local line = pointsList:AddLine(tostring(k), tostring(pt))
    end
    
    pointsList.OnRowRightClick = function(lst, index, line)
        local menu = DermaMenu()
        menu:AddOption("Add Point Before", function()
            RunConsoleCommand("measure_insert", line:GetValue(1))
        end)
        menu:AddOption("Add Point Before by Coordinate", function()
            Derma_StringRequest("Add Point",
                                "Enter X, Y, and Z, separated by commas:",
                                "",
                                function(text)
                                    text = text:Trim()
                                    if text:match("[%-0-9%.]+,? [%-0-9%.]+,? [%-0-9%.]+") then
                                        args = string.Explode(" ", text)
                                        RunConsoleCommand("measure_insert", line:GetValue(1), unpack(args))
                                    end
                                end)
        end)
        menu:AddOption("Add Orthogonal Line Before", function()
            RunConsoleCommand("measure_insert_ortho", line:GetValue(1))
        end)
        menu:AddOption("Replace Point", function()
            RunConsoleCommand("measure_replace", line:GetValue(1))
        end)
        menu:AddOption("Replace Point by Coordinate", function()
            Derma_StringRequest("Add Point",
                                "Enter X, Y, and Z, separated by commas:",
                                "",
                                function(text)
                                    text = text:Trim()
                                    if text:match("[%-0-9%.]+,? [%-0-9%.]+,? [%-0-9%.]+") then
                                        args = string.Explode(" ", text)
                                        RunConsoleCommand("measure_replace", line:GetValue(1), unpack(args))
                                    end
                                end)
        end)
        menu:AddOption("Delete Point", function()
            RunConsoleCommand("measure_remove", line:GetValue(1))
        end)
        menu:AddOption("Copy Coordinates", function()
            SetClipboardText(line:GetValue(2))
        end)
        menu:Open()
    end
    
    AddButton(panel, "Copy Total Distance", function()
        SetClipboardText(SaitoHUD.MeasureLength)
    end)
end

local panels = {
    Help = {"Help", HelpPanel},
    Tools = {"Tools", ToolPanel},
    Sampling = {"Sampling", SamplingPanel, {SwitchConVar = "sample_draw"}},
    Overlay = {"Overlay", OverlayPanel},
    Filtering = {"Filtering", EntityHighlightingPanel},
    Surveying = {"Surveying", SurveyPanel},
    Measuring = {"Measuring", MeasuringPanel},
}

--- PopulateToolMenu hook.
local function PopulateToolMenu()
    _SaitoHUDToolMenuPopulated = true
    
    for k, v in pairs(panels) do
        spawnmenu.AddToolMenuOption("Options", "SaitoHUD", "SaitoHUD" .. k,
                                    v[1], "", "", v[2], v[3])
    end
end

--- Selectively update the measuring panel.
function SaitoHUD.UpdateMeasuringPanel()
    pointsList:Clear()
    
    for k, pt in pairs(SaitoHUD.MeasurePoints) do
        local line = pointsList:AddLine(tostring(k), tostring(pt))
    end
end

--- Updates the panels.
function SaitoHUD.UpdatePanels()
    for k, v in pairs(panels) do
        assert(v[2])(GetControlPanel("SaitoHUD" .. k))
    end
end

hook.Add("PopulateToolMenu", "SaitoHUD.PopulateToolMenu", PopulateToolMenu)

LoadQuickFilters()

if _SaitoHUDToolMenuPopulated and SaitoHUD.Reloading then
    Msg("Updating panels...\n")
    SaitoHUD.UpdatePanels()
end