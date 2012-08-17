--[[
   no copyright by Vlorn

    This file is part of DKPmon_EPGPCSV.

    DKPmon_CSV is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    DKPmon_CSV is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with DKPmon_EPGPCSV; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
    
     This Module is based on the original work by Daniel D. Neilson and modified 
    for use with the Discord EPGP Loot system. It should work with any EPGP type mod to
    to the DKPmon system.
    The primary difference from the native DKPmon_CSV mod is that DKPmon_EPGPCSV allows for
    the importing and exporting of both the points earned and points spent for a given player.


	This file has been modded to support the EPGP methods of points storage, the
	CSV MUST be formated with the following conventions
	 "<name>:<class>:<level>:<race>:<pool 0 pointsEarned>:<pool 0  pointsSpent>:<pool 1 pointsEarned>:... etc"
]]


-- Only works with dbversion 2.0
if DKPmon.DBDefaults.dbversion ~= 2.0 then return end

local AceOO = AceLibrary("AceOO-2.0")
local Import = AceOO.Class(DKPmon_ImportBaseClass)
local L = AceLibrary("AceLocale-2.2"):new("DKPmon_EPGPCSV")

--[[
Initialize
Description:
  Called from DKPmon's OnEnable() function to initialize this module, if required
Input: none
Returns: none
]]
function Import:Initialize()
   --
end

--[[
GetFubarItem
Description:
  Called to retreive the module's fubar menu
Input: none
Output: none
]]
function Import:GetFubarItem()
   if self.fubaritem ~= nil then return self.fubaritem end
   self.fubaritem = { 
      type = 'execute',
      name = L['EPGP Points database CSV import'],
      desc = L['Overwrite your current points database with the database stored in DKPmon_CSV/importdata.lua'],
      func = function()
		StaticPopup_Show("DKPMON_CSV_IMPORT_CONFIRM")
	     end
   }
   return self.fubaritem
end

StaticPopupDialogs["DKPMON_CSV_IMPORT_CONFIRM"] = {
   text = L["Doing this will wipe your current points database. Are you positive you want to continue?"],
   button1 = L["Yes"],
   button2 = L["No"],
   OnAccept = function()
                 Import:PerformImport()
              end,
   OnCancel = function() end,
   sound = "levelup2",
   timeout = 10,
   whiledead = 1,
   hideOnEscape = 1
}

--[[
PerformImport
Description:
  Wipes out the DKPmon points database and replaces it with the data stored in the importdata.lua file
Input: none
Returns: none
]]
function Import:PerformImport()
   -- Wipe the current table
   DKPmon.PointsDB:WipeDatabase()
--   DKPmon:TableDelete(DKPmon.db.realm.DKP.db)
--   DKPmon.db.realm.DKP.db = {}
   local dkpsys = DKPmon.DKP:Get()

   local classnames = { 
      ["WARRIOR"] = 0, ["MAGE"] = 0, ["HUNTER"] = 0, 
      ["PRIEST"] = 0, ["PALADIN"] = 0, ["SHAMAN"] = 0,
      ["ROGUE"] = 0, ["DRUID"] = 0, ["WARLOCK"] = 0,
      ["DEATHKNIGHT"] = 0
   }
    
   -- Go through each string in DKPmon_CSV_Import_Data, and perform the import.
   local line, str
   for line, str in ipairs(DKPmon_EPGPCSV_Import_Data) do
      -- String format:  "<name>:<class>:<level>:<race>:<pool 0 pointsEarned>:<pool 0  pointsSpent>:<pool 1 pointsEarned>:... etc"

      local parse = { strsplit(":", str) }
      local name, class, level, race = parse[1], parse[2], tonumber(parse[3]), parse[4]
	  if (level == nil) then
      	level = 80
      end      
      --DKPmon:Print(name)
      local cap_char = string.upper(string.sub(name, 1, 1));
      --DKPmon:Print("blank-"..cap_char.."-blank?");
      if (cap_char == "") then      	
      	cap_char = string.sub(name, 1, 2)
      end
      name = cap_char..string.lower(string.sub(name, 2))
      class = string.upper(class)
      level = tonumber(level)
      race = string.upper(string.sub(race, 1, 1))..string.lower(string.sub(race, 2))
--[[
      if guild == "" then
	 guild = "Not guilded"
      end
]]
      -- Validate all the character information
      if name == "" or classnames[class] == nil or level == nil or race == "" then
	 DKPmon:Print(string.format(L["CSV Import -- string %d is invalid; skipping"], line))
      else
	 local charInfo = {
	    name = name, class = class, level = level, race = race --, guild = guild
	 }
	 local p = 1
	 local d = 1
	 while parse[d+4] ~= nil do
	    local earned = tonumber(parse[d+4])
	    local spent = tonumber(parse[d+5])
	    if earned ~= nil then
        DKPmon.PointsDB:SetPoints(charInfo, p, earned, spent)
  	    end
	    p = p + 1
	    d = d + 2
	 end
      end
   end
   DKPmon:Print(L["CSV Import complete"])
end

DKPmon.ImpExpModules:RegisterImportModule(Import, "EPGPCSV")
