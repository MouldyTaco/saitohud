-- SaitoHUD
-- Copyright (c) 2009, 2010 sk89q <http://www.sk89q.com>
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

local ignoreHooks = CreateClientConVar("saitohud_ignore_hooks", "0", false, false)

--- Checks whether the anti-unfair mode is triggered.
function SaitoHUD.AntiUnfairTriggered()
    if type(GAMEMODE) == nil then return false end
    if LocalPlayer():IsAdmin() or LocalPlayer():IsSuperAdmin() then return false end
    local name = tostring(GAMEMODE.Name)
    local folder = tostring(GAMEMODE.Folder)
    return __SaitoHUDUnfair == true and 
        string.find(name:lower(), "sandbox") == nil and 
        string.find(folder:lower(), "sandbox") == nil
end

function SaitoHUD.ShouldIgnoreHook()
    return ignoreHooks:GetBool()
end

function SaitoHUD.GetRefTrace()
    return util.TraceLine(util.GetPlayerTrace(LocalPlayer()))
end

function SaitoHUD.GetRefPos()
    return LocalPlayer():GetPos()
end

function SaitoHUD.MatchPlayerString(testName)
    local possibleMatch = nil
    testName = testName:lower()
    
    for _, ply in pairs(player.GetAll()) do
        local name = ply:GetName()
        
        if name:lower() == testName:lower() then
            return ply
        else
            if name:lower():find(testName, 1, true) then
                possibleMatch = ply
            end
        end
    end
    
    if possibleMatch then
        return possibleMatch
    else
        return nil
    end
end

function SaitoHUD.GetEntityInfoLines(showPlayerInfo)
    local tr = SaitoHUD.GetRefTrace()
    
    local lines = {}
    
    if ValidEntity(tr.Entity) then
        local r, g, b, a = tr.Entity:GetColor();
        lines = {}
        
        table.Add(lines,{
            "#" .. tostring(tr.Entity:EntIndex()) .. " [" .. tostring(tr.HitPos:Distance(LocalPlayer():GetPos())) .. "]",
            "Hit Pos: " .. tostring(tr.HitPos),
            "Class: " .. tostring(tr.Entity:GetClass()),
            "Position: " .. tostring(tr.Entity:GetPos()),
            "Size: " .. tostring(tr.Entity:OBBMaxs()-tr.Entity:OBBMins()),
            "Angle: " .. tostring(tr.Entity:GetAngles()),
            "Color: " .. string.format("%0.2f %.2f %.2f %.2f", r, g, b, a),
            "Model: " .. tostring(tr.Entity:GetModel()),
            "Material: " .. tostring(tr.Entity:GetMaterial()),
            "Velocity: " .. tostring(tr.Entity:GetVelocity()),
            "Local: " .. tostring(tr.Entity:WorldToLocal(tr.HitPos)),
        })
        
        if showPlayerInfo and tr.Entity:IsPlayer() then
            table.Add(lines, {
            "",
            "Name: " .. tostring(tr.Entity:Name()),
            "SteamID: " .. tostring(tr.Entity:SteamID()),
            "Ping: " .. tostring(tr.Entity:Ping()),
            "Health: " .. tostring(tr.Entity:Health()),
            "Armor: " .. tostring(tr.Entity:Armor()),
            "Weapon: " .. tostring(tr.Entity:GetActiveWeapon()),
            "Kills: " .. tostring(tr.Entity:Frags()),
            "Deaths: " .. tostring(tr.Entity:Deaths()),
            })
        end
    else
        if tr.Hit then
            lines = {
                "[" .. tostring(tr.HitPos:Distance(LocalPlayer():GetPos())) .. "]",
                "Hit Pos: " .. tostring(tr.HitPos),
            }
        end
    end
    
    return lines
end

function SaitoHUD.DumpEntityInfo()
    local lines = SaitoHUD.GetEntityInfoLines()
    
    if table.Count(lines) > 0 then
        for _, s in pairs(lines) do
            Msg(s .. "\n")
        end
    end
end

function SaitoHUD.ShowHint(msg, t, c)
    if not t then t = 10 end
    if not c then c = NOTIFY_GENERIC end
    GAMEMODE:AddNotify(msg, c, t);
    surface.PlaySound("ambient/water/drip" .. math.random(1, 4) .. ".wav")
end

function SaitoHUD.OpenHelp()
    if SaitoHUD.HelpWindow and SaitoHUD.HelpWindow:IsValid() then
        return
    end
    
    local contents = ""
    
    if file.Exists("../addons/SaitoHUD/docs.html") then
        contents = file.Read("../addons/SaitoHUD/docs.html")
    else
        Error("addons/SaitoHUD/docs.html doesn't exist\n")
    end
    
    local frame = vgui.Create("DFrame")
    SaitoHUD.HelpWindow = frame
    frame:SetTitle("SaitoHUD Help")
    frame:SetDeleteOnClose(true)
    frame:SetScreenLock(true)
    frame:SetSize(math.min(780, ScrW() - 0), ScrH() * 4/5)
    frame:SetSizable(true)
    frame:Center()
    frame:MakePopup()
    
    local browser = vgui.Create("HTML", frame)
    browser:SetVerticalScrollbarEnabled(false)
    browser:SetHTML(contents)

    -- Layout
    local oldPerform = frame.PerformLayout
    frame.PerformLayout = function()
        oldPerform(frame)
        browser:StretchToParent(10, 28, 10, 10)
    end
    
    frame:InvalidateLayout(true, true)
end

concommand.Add("saitohud_help", function(ply, cmd, args)
    SaitoHUD.OpenHelp()
end)

--- We store it now so that players can't disable it mid-game -- that's not enough
-- of a deterrent
if __SaitoHUDUnfair == nil and not file.Exists("saitohud/no_deterrent.lck") then
    __SaitoHUDUnfair = true
end