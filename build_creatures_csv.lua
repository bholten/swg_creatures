local lfs = require("lfs")

-- Core3 scripts use some functions that are defined in C++. We mostly
-- want to ignore these (e.g. includeFile), because they aren't really
-- relevant to scraping the data
local safe_env = {
   setmetatable = setmetatable,
   getmetatable = getmetatable,
   ipairs	= ipairs,
   pairs	= pairs,
   table	= table,
   -- ignore
   includeFile		= function(s) end,
   addTemplate		= function(s) end,
   addDressGroup	= function(s) end,
   addWeapon		= function(s) end,
   addOutfitGroup	= function(s) end,
   --addLairTemplate	= function(s) end,
   CONVERSABLE		= 0,
   Lair			= {},
   -- object flags
   NONE				= 0x00,
   ATTACKABLE			= 0x01,
   AGGRESSIVE			= 0x02,
   OVERT			= 0x04,
   TEF				= 0x08,
   PLAYER			= 0x10,
   ENEMY			= 0x20,
   WILLBEDECLARED		= 0x40,
   WASDECLARED			= 0x80,
   NPC				= 0x000001,
   PACK				= 0x000002,
   HERD				= 0x000004,
   KILLER			= 0x000008,
   STALKER			= 0x000010,
   BABY				= 0x000020,
   LAIR				= 0x000040,
   HEALER			= 0x000080,
   SCOUT			= 0x000100,
   PET				= 0x000200,
   DROID_PET			= 0x000400,
   FACTION_PET			= 0x000800,
   ESCORT			= 0x001000,
   FOLLOW			= 0x002000,
   STATIC			= 0x004000,
   STATIONARY			= 0x008000,
   NOAIAGGRO			= 0x010000,
   SCANNING_FOR_CONTRABAND	= 0x020000,
   IGNORE_FACTION_STANDING	= 0x040000,
   SQUAD			= 0x080000,
   EVENTCONTROL			= 0x100000,
   NOINTIMIDATE			= 0x200000,
   NODOT			= 0x400000,
   TEST				= 0x800000,
   LASTAIMASK			= 0x1000000,
   CARNIVORE			= 0x01,
   HERBIVORE			= 0x02,
   -- option bit masks
   NONE			= 0x00000000,
   ACTIVATED		= 0x00000001,
   VENDOR		= 0x00000002,
   INSURED		= 0x00000004,
   CONVERSE		= 0x00000008,
   HIBERNATING		= 0x00000010,
   YELLOW		= 0x00000020,
   FACTIONAGGRO		= 0x00000040,
   AIENABLED		= 0x00000080,
   INVULNERABLE         = 0x00000100,
   DISABLED             = 0x00000200,
   UNINSURABLE          = 0x00000400,
   INTERESTING          = 0x00000800,
   VEHICLE              = 0x00001000,
   HASSERIAL            = 0x00002000,
   WINGS_OPEN           = 0x00004000,
   JTLINTERESTING       = 0x00008000,
   DOCKING              = 0x00010000,
   DESTROYING           = 0x00020000,
   COMMABLE             = 0x00040000,
   DOCKABLE             = 0x00080000,
   EJECT                = 0x00100000,
   INSPECTABLE          = 0x00200000,
   TRANSFERABLE         = 0x00400000,
   INFLIGHT_TUTORIAL    = 0x00800000,
   SPACE_COMBAT_MUS     = 0x01000000,
   ENCOUNTER_LOCKED     = 0x02000000,
   SPAWNED_CREATURE     = 0x04000000,
   HOLIDAY_INTERESTING  = 0x08000000,
   LOCKED		= 0x10000000,
   -- AI agent
   MOB_HERBIVORE	= 1,
   MOB_CARNIVORE	= 2,
   MOB_NPC		= 3,
   MOB_DROID		= 4,
   MOB_ANDROID		= 5,
   MOB_VEHICLE		= 6,
   -- constants
   brawlernovice	= { {"melee1hlunge1",""},{"melee2hlunge1",""},{"polearmlunge1",""},{"unarmedlunge1",""} },
   marksmannovice	= { {"overchargeshot1",""},{"pointblanksingle1",""},{"pointblankarea1",""} },
   brawlermid		= { {"melee1hlunge1",""},{"melee1hhit1",""},{"melee1hbodyhit1",""},{"melee2hlunge1",""},{"melee2hhit1",""},{"melee2hheadhit1",""},{"polearmlunge1",""},{"polearmhit1",""},{"polearmleghit1",""},{"unarmedlunge1",""},{"unarmedhit1",""},{"unarmedstun1",""} },
   marksmanmid		= { {"overchargeshot1",""},{"pointblanksingle1",""},{"pointblankarea1",""},{"headshot1",""},{"bodyshot1",""},{"legshot1",""},{"fullautosingle1",""},{"diveshot",""},{"kipupshot",""},{"rollshot",""} },
   marksmanmaster	= { {"overchargeshot2",""},{"pointblanksingle1",""},{"pointblankarea1",""},{"diveshot",""},{"kipupshot",""},{"rollshot",""},{"bodyshot2",""},{"healthshot1",""},{"legshot2",""},{"fullautosingle1",""},{"actionshot1",""},{"headshot2",""},{"mindshot1",""},{"warningshot",""},{"suppressionfire1",""} },
   brawlermaster	= { {"unarmedlunge2",""},{"unarmedhit1",""},{"unarmedstun1",""},{"unarmedblind1",""},{"unarmedspinattack1",""},{"melee1hspinattack1",""},{"melee1hlunge2",""},{"melee1hdizzyhit1",""},{"melee1hhit1",""},{"melee1hbodyhit1",""},{"melee2hhit1",""},{"melee2hlunge2",""},{"melee2hheadhit1",""},{"melee2hsweep1",""},{"melee2hspinattack1",""},{"polearmlunge2",""},{"polearmhit1",""},{"polearmleghit1",""},{"polearmstun1",""},{"polearmspinattack1",""} },
   bountyhunternovice	= { {"firelightningsingle1",""},{"bleedingshot",""},{"underhandshot",""} },
   commandonovice	= { {"flamesingle1",""},{"fireacidsingle1",""} },
   carbineernovice	= { {"actionshot2",""},{"fullautosingle2",""},{"fullautoarea1",""},{"scattershot1",""},{"legshot3",""},{"burstshot1",""} },
   pistoleernovice	= { {"healthshot2",""},{"pointblanksingle2",""},{"pistolmeleedefense1",""},{"disarmingshot1",""} },
   riflemannovice	= { {"strafeshot1",""},{"mindshot2",""},{"flushingshot1",""},{"flurryshot1",""} },
   fencernovice		= { {"melee1hhit2",""},{"melee1hscatterhit1",""},{"melee1hhealthhit1",""},{"melee1hbodyhit2",""},{"melee1hblindhit1",""} },
   swordsmannovice	= { {"melee2hhit2",""},{"melee2harea1",""},{"melee2hheadhit2",""},{"melee2hspinattack2",""},{"melee2hmindhit1",""} },
   pikemannovice	= { {"polearmactionhit1",""},{"polearmhit2",""},{"polearmleghit2",""},{"polearmstun2",""},{"polearmsweep1",""} },
   tkanovice		= { {"unarmedhit2",""},{"unarmedbodyhit1",""},{"unarmeddizzy1",""},{"unarmedknockdown1",""} },
   bountyhuntermid	= { {"firelightningcone1",""},{"firelightningsingle1",""},{"bleedingshot",""},{"underhandshot",""},{"eyeshot",""},{"knockdownfire",""} },
   commandomid		= { {"flamecone1",""},{"flamesingle1",""},{"fireacidcone1",""},{"fireacidsingle1",""} },
   carbineermid		= { {"actionshot2",""},{"fullautosingle2",""},{"fullautoarea2",""},{"scattershot2",""},{"legshot3",""},{"burstshot2",""},{"wildshot1",""},{"chargeshot1",""},{"cripplingshot",""} },
   pistoleermid		= { {"bodyshot3",""},{"healthshot2",""},{"pointblanksingle2",""},{"pistolmeleedefense2",""},{"disarmingshot1",""},{"doubletap",""},{"stoppingshot",""} },
   riflemanmid		= { {"headshot3",""},{"strafeshot1",""},{"mindshot2",""},{"flushingshot2",""},{"flurryshot2",""},{"startleshot1",""} },
   fencermid		= { {"melee1hhit2",""},{"melee1hscatterhit1",""},{"melee1hhealthhit1",""},{"melee1hbodyhit3",""},{"melee1hblindhit2",""},{"melee1hdizzyhit2",""},{"melee1hspinattack2",""} },
   swordsmanmid		= { {"melee2hhit2",""},{"melee2harea2",""},{"melee2hheadhit3",""},{"melee2hspinattack2",""},{"melee2hmindhit2",""},{"melee2hsweep2",""} },
   pikemanmid		= { {"polearmactionhit2",""},{"polearmhit2",""},{"polearmleghit3",""},{"polearmstun2",""},{"polearmsweep2",""},{"polearmarea1",""},{"polearmspinattack2",""} },
   tkamid		= { {"unarmedhit2",""},{"unarmedbodyhit1",""},{"unarmeddizzy1",""},{"unarmedknockdown1",""},{"unarmedleghit1",""},{"unarmedcombo1",""},{"unarmedspinattack2",""} },
   bountyhuntermaster	= { {"firelightningcone1",""},{"firelightningcone2",""},{"firelightningsingle1",""},{"firelightningsingle2",""},{"bleedingshot",""},{"underhandshot",""},{"eyeshot",""},{"knockdownfire",""},{"torsoshot",""},{"confusionshot",""},{"fastblast",""},{"sprayshot",""} },
   commandomaster	= { {"flamecone1",""},{"flamecone2",""},{"flamesingle1",""},{"flamesingle2",""},{"fireacidcone1",""},{"fireacidcone2",""},{"fireacidsingle1",""},{"fireacidsingle2",""} },
   carbineermaster	= { {"actionshot2",""},{"fullautosingle2",""},{"fullautoarea2",""},{"wildshot2",""},{"scattershot2",""},{"legshot3",""},{"cripplingshot",""},{"burstshot2",""},{"suppressionfire2",""},{"chargeshot2",""} },
   pistoleermaster	= { {"healthshot2",""},{"pointblanksingle2",""},{"bodyshot3",""},{"pistolmeleedefense2",""},{"disarmingshot2",""},{"doubletap",""},{"stoppingshot",""},{"fanshot",""},{"pointblankarea2",""},{"multitargetpistolshot",""} },
   riflemanmaster	= { {"headshot3",""},{"strafeshot2",""},{"mindshot2",""},{"flushingshot2",""},{"startleshot2",""},{"flurryshot2",""} },
   fencermaster		= { {"melee1hhit3",""},{"melee1hscatterhit2",""},{"melee1hdizzyhit2",""},{"melee1hhealthhit2",""},{"melee1hspinattack2",""},{"melee1hbodyhit2",""},{"melee1hblindhit2",""} },
   swordsmanmaster	= { {"melee2hhit3",""},{"melee2harea3",""},{"melee2hspinattack2",""},{"melee2hsweep2",""},{"melee2hmindhit2",""},{"melee2hheadhit3",""} },
   pikemanmaster	= { {"polearmactionhit2",""},{"polearmarea2",""},{"polearmhit3",""},{"polearmleghit3",""},{"polearmspinattack2",""},{"polearmstun2",""},{"polearmsweep2",""} },
   tkamaster		= { {"unarmedhit3",""},{"unarmedleghit1",""},{"unarmedbodyhit1",""},{"unarmedheadhit1",""},{"unarmedspinattack2",""},{"unarmedcombo2",""},{"unarmedknockdown2",""},{"unarmeddizzy1",""} },
   lightsabermaster	= { {"saber1hheadhit1",""},{"saber1hheadhit2",""},{"saber1hhit3",""},{"saber1hcombohit3",""},{"saber1hflurry",""},{"saber1hflurry2",""},{"saber2hbodyhit2",""},{"saber2hbodyhit3",""},{"saber2hfrenzy",""},{"saber2hhit3",""},{"saber2hphantom",""},{"saber2hsweep3",""},
      {"saberpolearmdervish",""},{"saberpolearmdervish2",""},{"saberpolearmhit3",""},{"saberpolearmleghit3",""},{"saberpolearmspinattack3",""},{"saberslash1",""},{"saberslash2",""},{"saberthrow2",""} },
   forcepowermaster	= { {"forcelightningsingle2",""},{"forcelightningcone2",""},{"mindblast2",""},{"forceknockdown2",""},{"forceweaken2",""},{"forcethrow2",""},{"forcechoke",""},{"forceintimidate2",""} },
   forcewielder		={ {"forcelightningsingle1",""},{"mindblast1",""},{"forceweaken1",""},{"forceknockdown1",""},{"forcelightningcone1",""},{"forceintimidate1",""} },

   Creature = {
      objectName		= "",
      socialGroup		= "",
      faction			= "",
      level			= 0,
      chanceHit			= 0.000000,
      damageMin			= 0,
      damageMax			= 0,
      range			= 0,
      baseXp			= 0,
      baseHAM			= 0,
      armor			= 0,
      resists			= {0,0,0,0,0,0,0,0,0},
      meatType			= "",
      meatAmount		= 0,
      hideType			= "",
      hideAmount		= 0,
      boneType			= "",
      boneAmount		= 0,
      milk			= 0,
      tamingChance		= 0.000000,
      ferocity			= 0,
      pvpBitmask		= NONE,
      creatureBitmask		= NONE,
      diet			= 0,
      scale			= 1.0,
      templates			= {},
      lootGroups		= {},
      primaryWeapon		= "unarmed",
      secondaryWeapon		= "none",
      primaryAttacks		= {},
      secondaryAttacks		= { },
      conversationTemplate	= "",
      personalityStf		= "",
      optionsBitmask		= AIENABLED
   },

   CreatureTemplates = {},

   deepcopy = function(t)
      local u = { }
      for k, v in pairs(t) do u[k] = v end
      return setmetatable(u, getmetatable(t))
   end,

   -- Lairs
   Lair = {
      mobiles		= {},
      bossMobiles	= {},
      spawnLimit	= 0,
      buildingsVeryEasy = {},
      buildingsEasy	= {},
      buildingsMedium	= {},
      buildingsHard	= {},
      buildingsVeryHard = {},
      faction		= "neutral",
      mobType		= "creature",
      buildingType	= "lair"
   },

   LairTemplates = {},

   SpawnGroups = {},

   DestroyMissions = {}
}

function safe_env.merge(a, ...)
   local r = safe_env.deepcopy(a)

   for j,k in ipairs({...}) do
      for i, v in pairs(k) do
	 table.insert(r,v)
      end
   end

   return r
end

function safe_env.Creature:new (o)
   o = o or {}
   setmetatable(o, { __index = self })
   return o
end

function safe_env.CreatureTemplates:addCreatureTemplate(obj, file)
   if obj == nil then
      print("[addCreatureTemplate] Error: nil template specified for", file)
   else
      if self[file] then
	 print("[addCreatureTemplate] WARNING: DUPLICATE ENTRY", file)
      end

      self[file] = obj
      print("[addCreatureTemplate] Stored creature template:", file, obj)
   end
end

function safe_env.getCreatureTemplate(crc)
   return self[crc]
end

function safe_env.Lair:new (o)
   o = o or { }
   setmetatable(o, self)
   self.__index = self
   return o
end

function safe_env.addLairTemplate(obj, file)
   safe_env.LairTemplates[file] = obj
end

function safe_env.addSpawnGroup(str, obj)
   safe_env.SpawnGroups[str] = obj
end

function safe_env.addDestroyMissionGroup(str, obj)
   safe_env.DestroyMissions[str] = obj
end

--
-- Utils
--

function execute_script(filename)
   local chunk, err = loadfile(filename, "t", safe_env)

   if chunk then
      local success, errno = pcall(chunk)

      if not success then
	 print("Error executing script:", filename, errno)
	 return false
      end

      print("Successfully executed script:", filename)
      return true
   end

   print("Error loading script:", err)
   return false
end

function get_lua_files(dir, file_list)
   file_list = file_list or {}

   for file in lfs.dir(dir) do
      if file ~= "." and file ~= ".." then
	 local full_path = dir .. "/" .. file
	 local attr = lfs.attributes(full_path)

	 if attr then
	    if attr.mode == "directory" then
	       get_lua_files(full_path, file_list)
	    elseif file:match("%.lua") then
	       table.insert(file_list, full_path)
	    end
	 else
	    print("[get_lua_files] could not read file attributes:", file)
	 end
      end
   end

   return file_list
end

function execute_scripts(base_path)
   local files = get_lua_files(base_path)

   for _, file in ipairs(files) do
      if file ~= nil then
	 local r = execute_script(file)

	 if not r then
	    print("Error loading script:", file)
	 end
      end
   end
end

function write_to_file(filename, data)
   if data then
      local file = io.open(filename, "w")

      if not file then
	 print("Error: could not open file" .. filename)
	 return false
      end

      file:write(data)
      file:close()
      return true
   end
   return false
end

--
-- Creatures
--
function creature_is_mob_herb_or_carn(c)
   if not c or not c.mobType then
      return false
   end

   return c.mobType == safe_env.MOB_HERBIVORE or c.mobType == safe_env.MOB_CARNIVORE
end

function creature_headers()
   local headers = {
      "creatureName",
      "objectName",
      "socialGroup",
      "faction",
      "level",
      "chanceHit",
      "damageMin",
      "damageMax",
      "range",
      "baseXp",
      "baseHAM",
      "armor",
      "kinetic",
      "kineticEff",
      "energy",
      "energyEff",
      "blast",
      "blastEff",
      "heat",
      "heatEff",
      "cold",
      "coldEff",
      "electricity",
      "electricityEff",
      "acid",
      "acidEff",
      "stun",
      "stunEff",
      "lightsaber",
      "lightSaberEff",
      "meatType",
      "meatAmount",
      "hideType",
      "hideAmount",
      "boneType",
      "boneAmount",
      "milk",
      "tamingChance",
      "ferocity",
      "pvpBitmask",
      "creatureBitmask",
      "diet",
      "scale",
      "templates",
      "lootGroups",
      "primaryWeapon",
      "secondaryWeapon",
      "primarySpecialAttackOne",
      "primarySpecialAttackTwo",
      "secondarySpecialAttackOne",
      "secondarySpecialAttackTwo",
      "conversationTemplate",
      "personalityStf",
      "optionsBitmask"
   }

   return table.concat(headers, ",")
end

function parse_resist_array(arr)
   local function resist_value(num)
      local v = tonumber(num)
      local r = v

      if (v > 100) then
	 r = v - 100
      end

      local er = v <= 100 and v > 0

      return {
	 value = r,
	 is_effective_resist = er
      }
   end

   return {
      kinetic = resist_value(arr[1]),
      energy = resist_value(arr[2]),
      blast = resist_value(arr[3]),
      heat = resist_value(arr[4]),
      cold = resist_value(arr[5]),
      electricity = resist_value(arr[6]),
      acid = resist_value(arr[7]),
      stun = resist_value(arr[8]),
      lightsaber = resist_value(arr[9])
   }
end

function parse_special_attacks(creature)
   local primary = creature["primaryAttacks"]
   local secondary = creature["secondaryAttacks"]

   return {
      primarySpecialAttackOne = primary[1] and primary[1][1] or nil,
      primarySpecialAttackTwo = primary[2] and primary[2][1] or nil,
      secondarySpecialAttackOne = secondary[1] and secondary[1][1] or nil,
      secondarySpecialAttackTwo = secondary[2] and secondary[2][1] or nil
   }
end

function convert_to_csv(creature_name, creature)
   local function escape_csv(val)
      if type(val) == "string" then
	 return '"' .. val:gsub('"', '""') .. '"'
      elseif type(val) == "number" then
	 return tostring(val)
      elseif type(val) == "table" then
	 return "[TABLE]"
      elseif type(val) == "boolean" then
	 return tostring(val)
      else
	 return ""
      end
   end

   local function flatten_table(val)
      if type(val) ~= "table" then
	 return escape_csv(val)
      end

      local result = {}

      for _, entry in pairs(val) do
	 if type(entry) == "table" then
	    table.insert(result, table.concat(entry, ":"))
	 else
	    table.insert(result, tostring(entry))
	 end
      end

      return escape_csv(table.concat(result, "|"))
   end

   local resists = parse_resist_array(creature["resists"])
   local special_attacks = parse_special_attacks(creature)

   local row = {
      creature_name,
      flatten_table(creature["objectName"]),
      flatten_table(creature["socialGroup"]),
      flatten_table(creature["faction"]),
      flatten_table(creature["level"]),
      flatten_table(creature["chanceHit"]),
      flatten_table(creature["damageMin"]),
      flatten_table(creature["damageMax"]),
      flatten_table(creature["range"]),
      flatten_table(creature["baseXp"]),
      flatten_table(creature["baseHAM"]),
      flatten_table(creature["armor"]),
      flatten_table(resists["kinetic"]["value"]),
      flatten_table(resists["kinetic"]["is_effective_resist"]),
      flatten_table(resists["energy"]["value"]),
      flatten_table(resists["energy"]["is_effective_resist"]),
      flatten_table(resists["blast"]["value"]),
      flatten_table(resists["blast"]["is_effective_resist"]),
      flatten_table(resists["heat"]["value"]),
      flatten_table(resists["heat"]["is_effective_resist"]),
      flatten_table(resists["cold"]["value"]),
      flatten_table(resists["cold"]["is_effective_resist"]),
      flatten_table(resists["electricity"]["value"]),
      flatten_table(resists["electricity"]["is_effective_resist"]),
      flatten_table(resists["acid"]["value"]),
      flatten_table(resists["acid"]["is_effective_resist"]),
      flatten_table(resists["stun"]["value"]),
      flatten_table(resists["stun"]["is_effective_resist"]),
      flatten_table(resists["lightsaber"]["value"]),
      flatten_table(resists["lightsaber"]["is_effective_resist"]),
      flatten_table(creature["meatType"]),
      flatten_table(creature["meatAmount"]),
      flatten_table(creature["hideType"]),
      flatten_table(creature["hideAmount"]),
      flatten_table(creature["boneType"]),
      flatten_table(creature["boneAmount"]),
      flatten_table(creature["milk"]),
      flatten_table(creature["tamingChance"]),
      flatten_table(creature["ferocity"]),
      flatten_table(creature["pvpBitmask"]),
      flatten_table(creature["creatureBitmask"]),
      flatten_table(creature["diet"]),
      flatten_table(creature["scale"]),
      flatten_table(creature["templates"]),
      flatten_table(creature["lootGroups"]),
      flatten_table(creature["primaryWeapon"]),
      flatten_table(creature["secondaryWeapon"]),
      flatten_table(special_attacks["primarySpecialAttackOne"]),
      flatten_table(special_attacks["primarySpecialAttackTwo"]),
      flatten_table(special_attacks["secondarySpecialAttackOne"]),
      flatten_table(special_attacks["secondarySpecialAttackTwo"]),
      flatten_table(creature["conversationTemplate"]),
      flatten_table(creature["personalityStf"]),
      flatten_table(creature["optionsBitmask"])
   }

   local final = table.concat(row, ",")

   return final
end

function parse_creature_templates(creature_templates)
   local results = {}

   for creature_name, creature in pairs(creature_templates) do
      if type(creature) == "table" and creature_is_mob_herb_or_carn(creature) then
	 table.insert(results, convert_to_csv(creature_name, creature))
      end
   end

   return results
end

function build_csv()
   results = {}

   local templates = parse_creature_templates(safe_env.CreatureTemplates)

   for _, line in ipairs(templates) do
      if line ~= nil then
	 table.insert(results, line)
      else
	 print("Line was nil", file)
      end
   end

   results = table.concat(results, "\n")
   return results
end

function build_creature_db(filename, planets)
   local hds = creature_headers()
   local results = {hds}

   for _, planet in ipairs(planets) do
      execute_scripts(planet)
   end

   local data = build_csv(planet)
   table.insert(results, data)

   local csv = table.concat(results, "\n")
   local result = write_to_file(filename, csv)

   if result then
      print("Successfully wrote file")
   else
      print("CSV generation failed")
   end
end

local mobile_planets = {
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/corellia",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/dathomir",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/dantooine",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/endor",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/lok",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/naboo",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/rori",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/talus",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/tatooine",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/yavin4"
}

build_creature_db("creatures.csv", mobile_planets)

--
-- Lairs
--
local creature_dynamic_planets = {
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/lair/creature_dynamic/corellia",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/lair/creature_dynamic/dathomir",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/lair/creature_dynamic/dantooine",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/lair/creature_dynamic/endor",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/lair/creature_dynamic/lok",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/lair/creature_dynamic/naboo",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/lair/creature_dynamic/rori",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/lair/creature_dynamic/talus",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/lair/creature_dynamic/tatooine",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/lair/creature_dynamic/yavin4"
}

local creature_lair_planets = {
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/lair/creature_lair/corellia",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/lair/creature_lair/dathomir",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/lair/creature_lair/dantooine",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/lair/creature_lair/endor",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/lair/creature_lair/lok",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/lair/creature_lair/naboo",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/lair/creature_lair/rori",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/lair/creature_lair/talus",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/lair/creature_lair/tatooine",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/lair/creature_lair/yavin4"
}

function build_lair_tables()
   local lair_rows = {"lairName,spawnLimit,buildingsVeryEasy,buildingsEasy,buildingsMedium,buildingsHard,buildingsVeryHard"}
   local creature_rows = {"lairName,creatureName,type,count"}

   for _, dynamic in ipairs(creature_dynamic_planets) do
      execute_scripts(dynamic)
   end

   for _, lair in ipairs(creature_lair_planets) do
      execute_scripts(lair)
   end

   for lair_template, lair_name in pairs(safe_env.LairTemplates) do
      local lair_v = {
	 lair_name,
	 lair_template["spawnLimit"],
	 lair_template["buildingsVeryEasy"][1], -- frankly, don't care about this data anyway
	 lair_template["buildingsEasy"][1],
	 lair_template["buildingsMedium"][1],
	 lair_template["buildingsHard"][1],
	 lair_template["buildingsVeryHard"][1]
      }
      local lair_row = table.concat(lair_v, ",")
      table.insert(lair_rows, lair_row)

      local mobiles = lair_template["mobiles"]

      for _, mobile in ipairs(mobiles) do
	 local mobile_v = {
	    lair_name,
	    mobile[1],
	    "mobile",
	    mobile[2]
	 }
	 print("mobile value:", mobile_v[1], mobile[2], mobile[3], mobile[4])
	 table.insert(creature_rows, table.concat(mobile_v, ","))
      end

      local boss_mobiles = lair_template["bossMobiles"]

      for _, boss in ipairs(boss_mobiles) do
	 local boss_v = {
	    lair_name,
	    boss[1],
	    "boss",
	    boss[2]
	 }
	 table.insert(creature_rows, table.concat(boss_v, ","))
      end
   end


   local lair_results = table.concat(lair_rows, "\n")
   local creature_results = table.concat(creature_rows, "\n")

   write_to_file("lairs.csv", lair_results)
   write_to_file("lair_mobiles.csv", creature_results)
end


build_lair_tables()

--
-- Spawn Groups and Destroy Missions
--
local spawn_zones_planets = {
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/spawn/corellia",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/spawn/dathomir",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/spawn/dantooine",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/spawn/endor",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/spawn/lok",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/spawn/naboo",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/spawn/rori",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/spawn/talus",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/spawn/tatooine",
   "submodules/Core3/MMOCoreORB/bin/scripts/mobile/spawn/yavin4"
}

function build_spawn_groups()
   local spawn_groups = {"spawnGroupName,minLevelCeiling,lairTemplateName,spawnLimit,minDifficulty,maxDifficulty,numberToSpawn,weighting,size"}

   for _, planet_spawns in ipairs(spawn_zones_planets) do
      execute_scripts(planet_spawns)
   end

   local planet_missions = "submodules/Core3/MMOCoreORB/bin/scripts/mobile/spawn/destroy_mission"
   execute_scripts(planet_missions)

   for spawn_group_name, spawn_group in pairs(safe_env.SpawnGroups) do
      local lair_spawns = spawn_group["lairSpawns"]

      for _, lair_spawn in ipairs(lair_spawns) do
	 local lair_spawns_row = {
	    spawn_group_name,
	    "",
	    lair_spawn["lairTemplateName"],
	    lair_spawn["spawnLimit"],
	    lair_spawn["minDifficulty"],
	    lair_spawn["maxDifficulty"],
	    lair_spawn["numberToSpawn"],
	    lair_spawn["weighting"],
	    lair_spawn["size"]
	 }
	 local lair_spawns_txt = table.concat(lair_spawns_row, ",")

	 table.insert(spawn_groups, lair_spawns_txt)
      end
   end

   for destroy_mission_name, destroy_mission in pairs(safe_env.DestroyMissions) do
      local min_level_ceiling = destroy_mission["minLevelCeiling"]
      local lair_spawns = destroy_mission["lairSpawns"]
      print("Destroy mission:", destroy_mission_name)
      print("Min Level:", min_level_ceiling)

      for _, lair_spawn in ipairs(lair_spawns) do
	 local lair_spawns_row = {
	    destroy_mission_name,
	    min_level_ceiling,
	    lair_spawn["lairTemplateName"],
	    lair_spawn["minDifficulty"],
	    lair_spawn["maxDifficulty"],
	    "",
	    "",
	    lair_spawn["size"]
	 }
	 local lair_spawns_txt = table.concat(lair_spawns_row, ",")
	 print(lair_spawns_txt)
	 table.insert(spawn_groups, lair_spawns_txt)
      end
   end

   local lair_spawn_groups = table.concat(spawn_groups, "\n")
   write_to_file("lair_spawn_groups.csv", lair_spawn_groups)
end


build_spawn_groups()
