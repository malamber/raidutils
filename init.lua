---@diagnostic disable: undefined-field, assign-type-mismatch
--print('====== Raid Settings =======')

local mq           = require("mq")
require("ImGui")
--local common       = require("rip.common")
--local op           = require("raidutils_options")
--local grps 		   = require("raidutils_groups")
--local log          = common.getLog()

local UI_WIDTH = 450
local UI_HEIGHT = 500
local UI_LEFT = 150
local UI_PADDING = 5

local def = {
    class = mq.TLO.Me.Class.ShortName(),
    name  = mq.TLO.Me.CleanName(),
    debug = true,
    pulse = 500,
	home  = "",
	raids = "",
	options = {		
		filename    = mq.luaDir.."rip/utils/ru_options.lua",
		guildtrophy = false,
		guildtribute = false,
		autosave = true,
	},
	filename = mq.luaDir.. "/rip/utils/raidsettings.lua",
	ui       = { 
		inventory = { 
			search     = "",
			filtertype = 1,
			filtertoon = 1,
		},
		
		confirm    = {	disband = false, },
		coin       = { sortbycount = false },
		gear       = { selected = 1, colorexpac=true },
		minimized  = false,
        opengui    = true,
		message    = {
			text = "",
			color = ImVec4(1,1,1,1)
		},

        width      = UI_WIDTH,
        height     = UI_HEIGHT,
		tab        = {
			height = UI_HEIGHT -100
		},
		left       = { width = UI_LEFT },
		settings   = {
			hide   = false,
			width = UI_WIDTH - UI_LEFT - UI_PADDING *3 - 20
		}
    },
}

local data = {
	peers = {},
	gear = {
		items = {}
	},
	find = {
		items = {},
	},
	random = {},
	coin = {
		results = {},
		types   = {
			["Laurion Inn Voucher"] = { "LS", 500, true },
			["Shalowain's Private Reserve"] = { "LS", 450, false},
			["Spiritual Medallions"] = { "NoS",450, false}
		}
	 },
	 modes = {
		"Manual",
		"Assist",
		"Chase",
		"Vorpal",
		"Tank",
		"PullerTank",
		"PullerAssist",-- = 6,
		"SicTank",--      = 7,
		"HunterTank"--   = 8
	}
	
}

options = {
	["Debug"] = { name = "Debug", value = false },
}


local dc = "//cw "

local slots = {	"ear","ring","neck","head","chest","arms","legs","hands","feet","wrist","waist","charm","face","shoulders","back","primary","secondary","range"}

local function isRaid()
	return mq.TLO.Raid.Members() > 0
end

eqbc = {
	bcaa = function (str)
		--log.debug("bcaa "..str)
		mq.cmd("/bcaa /"..str)
	end,
	bca = function (cmd, val)
		mq.cmd("/squelch /bca "..dc.." ".. cmd.." "..tostring(val).." nosave")
	end,
	all = function (cmd, val)
		mq.cmd("/squelch /bcaa "..dc.." ".. cmd.." "..tostring(val).." nosave")
	end,
	group = function (cmd, val)
		mq.cmd("/squelch /bcga "..dc.." "..cmd.." "..val.. " nosave")
	end,
	toon = function (toon, cmd, val)
		mq.cmd("/squelch /bct "..toon.." "..dc.." "..cmd.." "..val)
	end,
	peers = function ()
		names = mq.TLO.EQBC.Names()
		tn = {}
		for i in string.gmatch(names, "%S+") do
			toon = nil
			if isRaid() then
				toon = mq.TLO.Raid.Member(i)
			else
				toon = mq.TLO.Group.Member(i)
			end

			table.insert(tn, toon)
		end
		return tn
	end
}
local function findClass(class)
	toons = eqbc.peers()
	for index, value in ipairs(toons) do
		if value.Class() == class then
			return value.Name()
		end
	end
	return nil
end
local settings = {
	{ class = "ALL", name = "Mode", value = 1,  show = true },
	{ class = "ALL", name = "UseAoE", value = true,  show = true },
	{ class = "ALL", name = "AoECount", value = 10,  show = true, aoe=true },
	--{ class = "ALL", name = "BurnCount", value = 10,  show = true },
	{ class = "ALL", name = "BurnAllNamed", value = false,  show = true },
	{ class = "ALL", name = "BurnAlways", value = false,  show = true },
	{ class = "ALL", name = "UseAlliance", value = true,  show = true },
	{ class = "ALL", name = "UseMelee", value = false,  show = true },
	{ class = "ALL", name = "RaidMode", value = true,  show = true, raid=true },
	{ class = "ALL", name = "RaidAssist", value = 1,  show = true, raid=true },
	{ class = "ALL", name = "UseGlyph", value = true,  show = false },
	--{ class = "ALL", name = "CampRadius", value = 200,  show = true },
	-- Class specific
	{ class = "CLR", name = "DiAll", value = true,  show = true, raid=true },
	{ class = "SHD", name = "UseInsidious", value = true,  show = true, aoe=true },

	{ class = "WIZ", name = "UseRune", value = false,  show = true },
	{ class = "WIZ", name = "UseShieldOfFate", value = false,  show = true },
}

raidfiles  = {
    { "LS", "Return of Kanghammer", "", "eldar", "/nav door OBJ_SWITCH_HALLDOOR_TWELVE CLICK"},
    { "LS","Plane of Mischief", "mischief.lua","mischiefplane", "/nav door OBJ_SWITCH_HALLDOOR_FOURTEEN CLICK"},
    { "LS","Timorous Deep", "timor.lua","timorousfalls", "/travelto timorousfalls"},
    { "LS","Moors of Nokk", "nokk.lua","moorsofnokk", "/travelto moorsofnokk" },
    { "LS","Ankexfen Keep", "ankexfen.lua","ankexfen", "/travelto ankexfen"},
    { "LS","Hero's Forge","forge.lua","herosforge", "/travelto herosforge"},
    { "LS","Final Fugue", "fugue.lua", "pallomen", "/travelto pallomen"},
    { "LS","Artisan and the Druid", "unkempt.lua","unkemptwoods", "/travelto unkemptwoods"},
	{ "NoS", "Shiknar Queen", "shiknar.lua", "paludal"},
    { "NoS", "Under Siege", "undersiege.lua", "sharval"},
    { "NoS", "Pit Fight", "pitfight.lua","sharval"},
    { "NoS", "Mean Streets", "meanstreets.lua", "sharval"},
    { "NoS", "When One Door Closes", "shadowhaven.lua", "shadowhaven"},
    { "NoS", "Myconid Mutiny", "myconid.lua", "deepshade"},
    --{ "NoS", "Dance of the Demiurge", "", "deepshade"},
    --{ "NoS", "The Spirit Fades", "grakaw", "deepshade"},
    { "NoS", "The Shadows Move", "firefall.lua", "firefall"}
}

filtertoons = { "All Toons"}
filtertypes = { "All Types", "inventory","worn","aug","collect", "depot"}

local invcolors = {
	aug = ImVec4(1,.8,.8, 1),
	inv = ImVec4(.8,.8, 1,1),
	worn = ImVec4(.8,1,.8,1),
	bank = ImVec4(1,.8,1,1),
	shared = ImVec4(.8,1,1,1),
	depot = ImVec4(1,1,.8,1)
}

local tiercolors = {
	t1group = ImVec4(1,.75, .75, 1),
	t3group = ImVec4(1,.5,.5,1),
	t1raid = ImVec4(.25,.5,1,1),
	t2raid = ImVec4(.5,.5,1,1),
	other = ImVec4(1,1,1,1),
}
local expaccolors = {
	ls = ImVec4(.5, .75, 1, 1),
	nos = ImVec4(.5, 1, .5, 1),
	tol = ImVec4(1, .75, .5, 1),
	anni = ImVec4(.75, .25, .5, 1)
}

local function runLua(lua, args)
	print("/lua run \""..def.home.."\\"..lua.."\" ".. args)
	eqbc.bcaa("/lua run \""..def.home.."\\"..lua.."\" ".. args)
end

local function asset(name)
	--print(def.home.. "/res/"..name)
	return mq.CreateTexture( def.home.. "/res/"..name)
end
icons = {}
local function createAssets()
	icons = {
		rip     = asset("rip.png"),
		burnon  = asset("burnon.png"),
		burnoff = asset("burnoff.png"),
		play    = asset("play.png"),
		stop    = asset("stop.png"),
		tribon  = asset("tributeon.png"),
		triboff = asset("tributeoff.png"),
		pson    = asset("pson.png"),
		psoff   = asset("psoff.png"),
		potions = asset("potions.png")
	}
end
local function createTextureID(file)
	return mq.CreateTexture(mq.TLO.Lua.Dir().."/rip/res/"..file):GetTextureID()
end

local function ImageButton(strid, icon,size, callback)
	local color   = ImVec4(1,1,1, 1)
	local tint    = ImVec4(0,0,0, 0)
	local size    = size or ImVec2(32, 32)
	local uv0     = ImVec2(0,0)
	local uv1     = ImVec2(1,1)
	if(ImGui.ImageButton(strid, icon:GetTextureID(), size, uv0, uv1, tint, color)) then
		if(callback ~= nil) then callback() end
	end
end

local raidgear = {
	{ "Eternal",    "T2 Raid",  "LS", tiercolors.t2raid },
	{ "Perpetual",  "T3 Group", "LS", tiercolors.t3group },
	{ "Gallant",    "T1 Group", "LS", tiercolors.t1group },
	{ "Heroic",     "T1 Raid",  "LS", tiercolors.t1raid },
	{ "Suffering",     "T1 Raid",  "LS", tiercolors.t1raid  },
	{ "Trinket of the Fanatic",     "T1 Raid",  "LS", tiercolors.t1raid  },
	{ "Bijou of Hope",     "T1 Raid",  "LS", tiercolors.t1raid  },
	{ "Sprung Fingercuff",     "T1 Raid",  "LS", tiercolors.t1raid  },
	{ "Heroic",     "T1 Raid",  "LS", tiercolors.t1raid  },
	{ "Master's Ring",     "T1 Raid",  "LS", tiercolors.t1raid  },
	{ "Heroic",     "T1 Raid",  "LS", tiercolors.t1raid  },
	{ "Cape of Hate",     "T1 Raid",  "LS", tiercolors.t1raid  },
	{ "Insignia of the King's Hand",     "T1 Raid",  "LS", tiercolors.t1raid  },
	{ "Cooper's Bone Chew",     "T1 Raid",  "LS", tiercolors.t1raid  },
	{ "Spaulders of the Hand",     "T1 Raid",  "LS", tiercolors.t1raid  },
	{ "Chalice of Autumn Wine",     "T1 Raid",  "LS", tiercolors.t1raid  },
	{ "Gilded Staff of the Master Magus",     "T1 Raid",  "LS", tiercolors.t1raid  },
	{ "Fortuitous Scepter of Xev Bristlebane",     "T1 Raid",  "LS", tiercolors.t1raid  },
	{ "Autumnal Guardian",     "T1 Raid",  "LS", tiercolors.t1raid  },
	{ "Elddar Cinch",     "T1 Raid",  "LS", tiercolors.t1raid  },
	{ "Crippling Waistwraps of the Gate",     "T1 Raid",  "LS", tiercolors.t1raid  },
	{ "Memoryforged",     "T1 Raid",  "LS", tiercolors.t1raid  },
	{ "Kejaan's Belt of Sagacity",     "T1 Raid",  "NoS", tiercolors.t1raid  },
	
	
	{ "Forgebound",     "T1 Group",  "LS", tiercolors.t1group },
	{ "Conflagrant",     "T1 Group",  "RoS", tiercolors.t1group },
	--{ "Heroic",     "T1 Raid",  "LS" },
	--{ "Heroic",     "T1 Raid",  "LS" },
	--{ "Heroic",     "T1 Raid",  "LS" },
	--{ "Heroic",     "T1 Raid",  "LS" },

	{ "Chalice of Kerran Heraldry", "T1 Raid", "NoS", tiercolors.t1raid  },
	{ "Luminosity", "T1 Raid", "NoS", tiercolors.t1raid  },
	{ "Ephyr's Extra Eider Effigy", "T1 Raid", "NoS", tiercolors.t1raid  },
	{ "Spectral",   "T2 Raid", "NoS", tiercolors.t2raid  },
	{ "Phantasmal",  "T3 Group", "NoS", tiercolors.t3group  },
	{ "Ascending",  "T1 Group", "NoS", tiercolors.t1group  },

	{ "Coagulated", "T2 Raid", "ToL", tiercolors.t2raid  },
	{ "Waning Gib", "T1 Raid", "ToL", tiercolors.t1raid  },
	{ "Deep Sang", "T1 Raid", "ToL", tiercolors.t1raid  },
	{ "Blood soaked", "T1 Raid", "ToL", tiercolors.t1raid  },
	{ "Loop of Infinite Twilight", "T1 Raid", "ToL", tiercolors.t1raid  },
	{ "Atraeth Centien xi Vius", "T1 Raid", "ToL", tiercolors.t1raid  }, 

	{ "Sterling Ring of Brilliance", "T2 Raid", "Anni", tiercolors.t2raid  },
	{ "Silver Ring of Adroitness", "T2 Raid", "Anni", tiercolors.t2raid  }, 
	{ "Sterling Mask of Brilliance", "T2 Raid", "Anni", tiercolors.t2raid  }, 
	{ "Collar of Legacies Lost", "Evolve", "LS", tiercolors.t2raid  }, 
	{ "Cloak of the Selenelion", "Evolve", "NoS", tiercolors.t2raid  }, 
}

local function getDefaultTableFlags()
	return bit32.bor(ImGuiTableFlags.Resizable,
		ImGuiTableFlags.Reorderable,
		ImGuiTableFlags.Hideable,
		--ImGuiTableFlags.Sortable,
		ImGuiTableFlags.RowBg,
		ImGuiTableFlags.Borders,
		ImGuiTableFlags.ScrollY
	)
end
local function setToolTip(desc)
    --ImGui.TextDisabled('?')
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 35.0)
        ImGui.Text(desc)
        ImGui.PopTextWrapPos()
        ImGui.EndTooltip()
    end
end

local function saveSettings(t_setting)
	print("Saving settings")
	mq.pickle(mq.luaDir.. "/rip/utils/raidsettings.lua", t_setting)
end

local function postSetting(name, val)
	if isRaid() then		
		eqbc.all(name, val)
	else
		eqbc.group(name, val)
	end
end

local function ui_tabOptions()
	if ImGui.BeginTabItem("Options") then
		local flags = bit32.bor(ImGuiTableFlags.Resizable,
			ImGuiTableFlags.Reorderable,
			ImGuiTableFlags.Hideable,
			ImGuiTableFlags.Borders
		)
		bsize = ImVec2(50, 25)
		
		tsize = ImGui.GetContentRegionAvailVec()
		if ImGui.BeginTable("##Options", 4,flags, tsize ) then
			ImGui.TableSetupColumn('Option1',    ImGuiTableColumnFlags.WidthAuto, -1.0, COL_HIDE)        
			ImGui.TableSetupColumn('Value1', ImGuiTableColumnFlags.WidthAuto, -1, COL_RAND) 
			ImGui.TableSetupColumn('Option2',   ImGuiTableColumnFlags.WidthAuto, -1, COL_VAL)  
			ImGui.TableSetupColumn('Value2',     ImGuiTableColumnFlags.WidthAuto, 40, COL_SET)

			for key, v in pairs(options) do
				ImGui.TableNextRow()
				ImGui.TableNextColumn()
				op_name = key
				v.value = ImGui.Checkbox(""..key, v.value)
			end

			ImGui.EndTable()
		end
	end
end

local function ui_tableSidebar()
	 local flags = bit32.bor(ImGuiTableFlags.Resizable,
                        ImGuiTableFlags.Reorderable,
                        ImGuiTableFlags.Hideable,
                        ImGuiTableFlags.Borders,
                        ImGuiTableFlags.ScrollY
					)
    COL_NAME = 0
	
		width, height  = ImGui.GetContentRegionAvail()
	if ImGui.BeginTable("##sidebar", 1, flags, def.ui.left.width, height, 0.0) then
		ImGui.TableSetupColumn('Tools', ImGuiTableColumnFlags.WidthStretch, -1.0, COL_NAME)
		
		ImGui.PushID('F_SCALE')
		ImGui.TableNextRow()
		ImGui.TableNextColumn()
		ImGui.Image(icons.rip:GetTextureID(), ImVec2(def.ui.left.width, def.ui.left.width))
		if(ImGui.Button("Parser", def.ui.left.width , 25)) then	mq.cmd("/raidutils parser")	end
		setToolTip("Run EQLogParser")

		bsize =  ImVec2(def.ui.left.width/2-15, def.ui.left.width/2-20)

		ImageButton("##tribon", icons.tribon, bsize, function ()
			eqbc.bcaa("/tribute personal on") eqbc.bcaa("/trophy personal on") 
		end)
		setToolTip("Tribute and Trophies On")
		ImGui.SameLine()
		ImageButton("##triboff", icons.triboff,bsize, function ()
			eqbc.bcaa("/tribute personal off") eqbc.bcaa("/trophy personal off") 
		end)
		setToolTip("Tribute and Trophies Off")

		ImageButton("##pson", icons.pson, bsize, function ()
			runLua("ru_powersource.lua","on" )
		end)
		setToolTip("Activate Powersource")
		ImGui.SameLine()
		--if(ImGui.Button("Toff", bsize)) then runLua("ru_powersource", "off")	end
		ImageButton("##psoff", icons.psoff,bsize, function ()	runLua("ru_powersource.lua", "off" ) end)
		setToolTip("Deactivate Powersource")
		
		if(ImGui.Button("Potions",  def.ui.left.width, 25)) then runLua("ru_potions", "")	end
		--ImageButton("potion", icons.potions,ImVec2(def.ui.left.width, 30), function ()	runLua("ru_potions.lua","" )	end)
		setToolTip("Use Potions/Poisons")
		

		ImGui.TableNextRow()
		ImGui.TableNextColumn()
		if ImGui.Button("Minimize",def.ui.left.width, 25) then	def.ui.minimized = true	end
		setToolTip("Minimize interface")

		ImGui.TableNextRow()
		ImGui.TableNextColumn()
		if def.ui.confirm.disband then
			ImGui.Text("Disband All?")
			if ImGui.Button("Yes", ImVec2(def.ui.left.width/2-5, 25)) then
				mq.cmd("/bcaa //raiddis")
				mq.cmd("/bcaa //dzquit")
				def.ui.confirm.disband = false
			end
			ImGui.SameLine()
			if ImGui.Button("No", ImVec2(def.ui.left.width/2-5, 25)) then
				def.ui.confirm.disband = false
			end
		else
			if ImGui.Button("Disband##all",  def.ui.left.width, 40) then -- and isRaid()) then
				--print("confirm disband")
				def.ui.confirm.disband = true
			end
		end
		ImGui.PopID()

		ImGui.EndTable()
	end
end

local function ui_dropDown(name, selected, items) return ImGui.Combo(name, selected, items, #items)	 end
local function ui_dropDownSlots(selected)	return ImGui.Combo("Slot", selected, slots, #slots) end
local function ui_dropDownMode(selected)	return ui_dropDown("##mode", selected, data.modes) end
local function ui_dropDownMA(selected)
	assist = {
		mq.TLO.Raid.MainAssist(1).Name() or "Unassigned",
		mq.TLO.Raid.MainAssist(2).Name() or "Unassigned",
		mq.TLO.Raid.MainAssist(3).Name() or "Unassigned",
	}
	selected = ui_dropDown("##ma", selected, assist)
	return selected
end

local function ui_tableSettings()
    local flags = getDefaultTableFlags()
    COL_HIDE = 0
    COL_RAND = 1
	COL_VAL = 2
	COL_SET = 3

	rowheight = 25
	local tsettings = settings
	--if def.ui.settings.hide then
		--tsettings = ui_showSettings(settings)
	--end
	count = #tsettings +1
	
	width, height = ImGui.GetContentRegionAvail()
    if ImGui.BeginTable('##settingtable', 4, flags, width, height, 0.0) then
		-- columns
        ImGui.TableSetupColumn('Show',    ImGuiTableColumnFlags.WidthAuto, -1.0, COL_HIDE)        
        ImGui.TableSetupColumn('Setting', ImGuiTableColumnFlags.WidthAlwaysAutoResize, 150, COL_RAND) 
        ImGui.TableSetupColumn('Value',   ImGuiTableColumnFlags.WidthStretch, -1, COL_VAL)  
        ImGui.TableSetupColumn('Set',     ImGuiTableColumnFlags.WidthAuto, 40, COL_SET)

        ImGui.TableSetupScrollFreeze(0, 1) -- Make row always visible
        -- Display data
        ImGui.TableHeadersRow()

		default_color = ImVec4(.3,1,1,1)
		override_color = ImVec4(.3,1,.3,1)

        local clipper = ImGuiListClipper.new()
        clipper:Begin(#tsettings)
        while clipper:Step() do
            for n = clipper.DisplayStart, clipper.DisplayEnd - 1, 1 do
				idx = n + 1
				setting_class = tsettings[idx].class
                setting_name  = tsettings[idx].name
            	setting_val   = tsettings[idx].value
				setting_show  = tsettings[idx].show

                ImGui.PushID('F_SCALE')
				ImGui.TableNextColumn()
				tsettings[idx].show = ImGui.Checkbox("##"..setting_name, setting_show)
                ImGui.TableNextColumn()
                ImGui.TextColored(default_color, setting_name)
                ImGui.TableNextColumn()
				if(setting_name == "Mode") then
					tsettings[idx].value = ui_dropDownMode(setting_val)
				elseif setting_name == "RaidAssist" and isRaid() then
					tsettings[idx].value = ui_dropDownMA(setting_val)
				elseif(type(setting_val) == "number") then
					tsettings[idx].value = ImGui.InputInt("##"..setting_val, setting_val, 1, 50, ImGuiInputTextFlags.EnterReturnsTrue)
				elseif type(setting_val) == "boolean" then
					tsettings[idx].value =ImGui.Checkbox("##Checkbox"..idx, setting_val)
				end

				ImGui.TableNextColumn()
				if ImGui.Button("Set##"..setting_name, 30, 20) then					
					postSetting(setting_name, tostring(tsettings[idx].value))
				end
                ImGui.PopID()
            end
        end
        ImGui.EndTable()
    end
end

local function bind_ru(...)
    local args = {...}
    local cmd = args[1]
	
	if cmd=="parser" then
		os.execute('start "eqlog" /D "C:\\Program Files\\EQLogParser\\" EQLogParser.exe')
	elseif cmd=="git" then
		git = "'C:\\Program Files\\Git\\cmd\\'"
		rip_home = "'".. mq.luaDir .. "\\rip\\'"
		cmd = "start 'git' /D ".. git.." git.exe pull "..rip_home
		print(cmd)
		os.execute(cmd)
	elseif cmd=="toggle" then
		def.ui.minimized = not def.ui.minimized
	end
end
function file_exists(name)
	name = def.raids .. "\\"..name
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end
local function ui_tableRowRaid(expac, name, raid, travel)
	bsize = ImVec2(50, 20)
	color = ImVec4(1,1,1,1)
	status =  mq.TLO.Lua.Script("rip/"..raid:gsub(".lua", "")).Status() --== 'RUNNING'
	--print(rraid.."=".. status)
	if status =='RUNNING' then
		color = ImVec4(.5,1,.5, 1)
	end
	ImGui.PushID('F_SCALE')
	ImGui.TableNextColumn()
	ImGui.TextColored(color, expac)
	ImGui.TableNextColumn()
	
	ImGui.TextColored(color, name)
	ImGui.TableNextColumn()
	
	ImGui.TextColored(color, raid)
	if raid ~= "" then			
		
		ImGui.TableNextColumn()
		if ImGui.Button("Run##"..raid, bsize) then
			eqbc.bcaa("/lua run rip/"..raid)
		end
		setToolTip(def.raids..raid)

		ImGui.TableNextColumn()
		if ImGui.Button("Stop##"..raid, bsize) then
			eqbc.bcaa("/lua stop rip/"..raid)
		end
	else
		ImGui.TableNextColumn()
		ImGui.TableNextColumn()
	end
	ImGui.TableNextColumn()
	if rtcmd and ImGui.Button("Go##"..raid, bsize)  then
		eqbc.bcaa(travel)
	end

	ImGui.PopID()
end
local function ui_tabRaids()

	if ImGui.BeginTabItem("Raids") then
		local flags = getDefaultTableFlags()
		
		
		tsize = ImGui.GetContentRegionAvailVec()
		if ImGui.BeginTable("##Raids", 6,flags, tsize ) then
			
            ImGui.TableSetupColumn('Expac', ImGuiTableColumnFlags.WidthAuto, -1, 0)
			ImGui.TableSetupColumn('Raid', ImGuiTableColumnFlags.WidthStretch, -1, 1)  
			ImGui.TableSetupColumn('File', ImGuiTableColumnFlags.WidthAuto, -1, 2)        
       		ImGui.TableSetupColumn('Start', ImGuiTableColumnFlags.WidthAuto, -1, 3)
            ImGui.TableSetupColumn('Stop', ImGuiTableColumnFlags.WidthAuto, -1, 4)
            ImGui.TableSetupColumn('Travel', ImGuiTableColumnFlags.WidthAuto, -1, 5)

			ImGui.TableHeadersRow()
			for _, value in ipairs(raidfiles) do
				rexpac=value[1]
				rname = value[2]
				rraid = value[3]
				rtcmd = value[5]
				--rf = def.home.."/".. rraid --..".lua"
				if rraid =="" or file_exists(rraid) then
					ui_tableRowRaid(rexpac, rname, rraid, rtcmd)
				end
			end
			
			ImGui.EndTable()
		end

		ImGui.EndTabItem()
	end
end
local function ui_tabTools()
	if def.debug then
		if ImGui.BeginTabItem("Tools") then
			-- git update
			if ImGui.Button("Git update") then
				mq.cmd("/raidutils git")
			end
			-- Random
			
			ImGui.EndTabItem()
		end
	end
end

local function inRaidZone()
	zsn = mq.TLO.Zone.ShortName()
	for _, value in ipairs(raidfiles) do
		if string.find(zsn, value[4]) then
			return true
		end
	end
	return false
end
local function ui_showRaidZone()
	zsn = mq.TLO.Zone.ShortName()
	for _, value in ipairs(raidfiles) do
		if string.find(zsn, value[4]) then
			if mq.TLO.Lua.Script("rip/"..value[3]).Status() == "RUNNING" then
				ImGui.TextColored(ImVec4(.75, 1, .75, 1), "Raid Running: ".. value[2])
			else
				ImGui.Text("Start Raid: ".. value[2])
			end
			
			ImGui.SameLine()
			if ImGui.Button("Run##"..value[3], ImVec2(50, 20)) then
				eqbc.bcaa("/lua run rip/"..value[3])
			end
			ImGui.SameLine()
			if ImGui.Button("Stop##"..value[3], ImVec2(50, 20)) then
				eqbc.bcaa("/lua stop rip/"..value[3])
			end
			--ImGui.Separator()
			return
		end
	end
end
local function getExpacColor(expac)
	if expac=="LS" then return expaccolors.ls	end
	if expac=="NoS" then return expaccolors.nos	end
	if expac=="ToL" then return expaccolors.tol	end
	if expac=="Anni" then return expaccolors.anni	end
	return ImVec4(1,1,1,1)
	
end
local function findItemDesc(name)
	name = string.gsub(name,"-"," ")
	for index, v in ipairs(raidgear) do
		if string.find(name, v[1]) then
			return v
		end
	end
	return { "", "", "",  tiercolors.other}
end

local function event_gstatus(line, arg1,arg2,arg3)
	table.insert(data.gear.items, { arg1, arg2, arg3})

	table.sort(data.gear.items, function (a,b)
		return a[1] < b[1] -- string.sub(a[1], 1,1) < string.sub(b[1], 1, 1) 
	end)
end


local function getInvColor(type)
	if type == "aug" then return invcolors.aug end
	if type == "bank" then return invcolors.bank end
	if type == "inventory" then return invcolors.inv end
	if type == "worn" then return invcolors.worn end
	if type == "depot" then return invcolors.depot end
	return ImVec4(1,1,1,1)
end

local function getFilteredInventory()
	fres = {}
	for index, value in ipairs(data.find.items) do
		filtered = false
		who = value[1]
		where = value[4]
		if def.ui.inventory.filtertoon > 1 and filtertoons[def.ui.inventory.filtertoon] ~= who then
			filtered = true
		elseif def.ui.inventory.filtertype > 1 and filtertypes[def.ui.inventory.filtertype] ~= where then
			filtered = true
		end

		if not filtered then
			table.insert(fres, value)
		end
	end
	--print(tostring(#fres))
	return fres
end
local function ui_tabInventory()
	local flags = getDefaultTableFlags()
	if ImGui.BeginTabItem("Find") then
		
		ImGui.PushItemWidth(150)
		def.ui.inventory.search,res = ImGui.InputText("##searchstr", def.ui.inventory.search, ImGuiInputTextFlags.EnterReturnsTrue)
		ImGui.SameLine()
		if(res or ImGui.Button("Search Item", ImVec2(50,20))) then
			data.find.items = {}			
			filtertoons = { "All Toons"}
			runLua("ru_find ", def.name.." \"".. def.ui.inventory.search.."\"")
		end
		ImGui.SameLine()
		if ImGui.Button("Clear", ImVec2(50,20)) then
			def.ui.inventory.search = ""		
			filtertoons = { "All Toons"}
			data.find.items = {}
		end
		ImGui.SameLine()
		ImGui.PushItemWidth(100)
		def.ui.inventory.filtertoon = ui_dropDown("Filters##ft", def.ui.inventory.filtertoon,filtertoons )
		ImGui.SameLine()
		def.ui.inventory.filtertype = ui_dropDown("##fty", def.ui.inventory.filtertype,filtertypes )

		filteredRes = getFilteredInventory()
		
		tsize = ImGui.GetContentRegionAvailVec()
		if ImGui.BeginTable("inv", 4, flags, tsize) then
			ImGui.TableSetupColumn('Who', ImGuiTableColumnFlags.WidthAuto, -1, 0)
			ImGui.TableSetupColumn('Item', ImGuiTableColumnFlags.WidthStretch, -1, 1)
			ImGui.TableSetupColumn('Count', ImGuiTableColumnFlags.WidthAuto, -1, 2)
			ImGui.TableSetupColumn('Type', ImGuiTableColumnFlags.WidthAuto, -1, 3)

			
        	ImGui.TableSetupScrollFreeze(0, 1) -- Make row always visible
			ImGui.TableHeadersRow()
			local clipper = ImGuiListClipper.new()
			clipper:Begin(#filteredRes)
			while clipper:Step() do
				for n = clipper.DisplayStart, clipper.DisplayEnd - 1, 1 do
					idx = n + 1-- + pcount * 20
					value = filteredRes[idx]
					who = value[1]
					item = value[2]
					count = value[3]
					where = value[4]	
					
					color = getInvColor(where)		
					ImGui.PushID(idx)
					--ImGui.TableNextRow()
					ImGui.TableNextColumn()
					ImGui.TextColored(color,who)
					ImGui.TableNextColumn()
					ImGui.TextColored(color,item)
					ImGui.TableNextColumn()
					ImGui.TextColored(color,tostring(count))
					ImGui.TableNextColumn()
					ImGui.TextColored(color,where)
					ImGui.PopID()
				end
			end
			ImGui.EndTable()
		end
		
		ImGui.EndTabItem()
	end
end

local function getLootList()
	lootcount = mq.TLO.AdvLoot.SCount()
	for i = 1, lootcount, 1 do
		lootitem = mq.TLO.AdvLoot.SList(i)
		id = lootitem.ID()
		name = lootitem.Name()
	end
end
local function ui_tabGear()
	local flags = getDefaultTableFlags()
		if mq.TLO.Window('LootWnd').Open() then
			getLootList()
		end
	if ImGui.BeginTabItem("Gear") then
		ImGui.PushItemWidth(150)
		def.ui.gear.selected = ui_dropDownSlots(def.ui.gear.selected)
		ImGui.SameLine()
		if ImGui.Button("Poll Status") then
			data.gear.items = {}
			st = slots[def.ui.gear.selected]
			if st == "ear" or st == "ring" or st == "wrist" then
				eqbc.bcaa("/status gear right " ..st )
				eqbc.bcaa("/status gear left " .. st)
			else
				mq.cmd("/bcaa //squelch /status gear " .. st)
			end
		end
		ImGui.SameLine()
		def.ui.gear.colorexpac = ImGui.Checkbox("Highlight Expac",def.ui.gear.colorexpac)
		ImGui.Separator()

		tsize = ImGui.GetContentRegionAvailVec()
		if ImGui.BeginTable("gearstatus", 6, flags, tsize) then
			ImGui.TableSetupColumn('Expac', ImGuiTableColumnFlags.WidthAuto, -1, 0)
			ImGui.TableSetupColumn('Type', ImGuiTableColumnFlags.WidthAuto, -1, 1)
			ImGui.TableSetupColumn('Slot', ImGuiTableColumnFlags.WidthAuto, -1, 2)
            ImGui.TableSetupColumn('Toon', ImGuiTableColumnFlags.WidthAuto, -1, 3)
            ImGui.TableSetupColumn('Item', ImGuiTableColumnFlags.WidthStretch, -1, 4)
            ImGui.TableSetupColumn('Copy', ImGuiTableColumnFlags.WidthAuto, 50, 5)

			ImGui.TableHeadersRow()
			for _, value in ipairs(data.gear.items) do
				slot = value[2]
				toon = value[1]
				item = value[3]
				id = findItemDesc(item)
				expac = id[3]
				raid = id[2]
				color = id[4] or tiercolors.other
				if def.ui.gear.colorexpac then
					color = getExpacColor(expac)
				end
				ImGui.TableNextRow()
				ImGui.TableNextColumn()
				ImGui.TextColored(color, expac)
				ImGui.TableNextColumn()
				ImGui.TextColored(color, raid)
				ImGui.TableNextColumn()
				ImGui.TextColored(color, slot)
				ImGui.TableNextColumn()
				ImGui.TextColored(color, toon)
				ImGui.TableNextColumn()
				ImGui.TextColored(color, item)
				ImGui.TableNextColumn()
				if expac == "" and item ~= " is empty."then
					if ImGui.Button("Copy##"..item..toon, ImVec2(40,20))  then					
						mq.cmd("/clip "..item)
					end
					setToolTip("Copy item name to clipboard.  Send it to Malamber in Discord")
				end
				
			end

			ImGui.EndTable()
		end
		ImGui.EndTabItem()
	end
end

showgroup = false

local function filterCoin()
	tres = {}
	for index, value in ipairs(data.coin.results) do
		expac = value[2]
		coin = data.coin.types[expac]
		if not coin[3] then
			table.insert(tres, value)
		end
	end
	return tres
end
local function ui_tabCurrency()
	local flags =getDefaultTableFlags()
	
	if ImGui.BeginTabItem("Coin") then
		if ImGui.Button("Scan", ImVec2(100,25)) then
			data.coin.results = {}
			runLua("ru_currency",def.name)
		end
		ImGui.SameLine()
		tsortbycount = ImGui.Checkbox("Sort by count", def.ui.coin.sortbycount)
		if tsortbycount ~= def.ui.coin.sortbycount then
			def.ui.coin.sortbycount = tsortbycount
			table.sort(data.coin.results, function (o1,o2)				
				if def.ui.coin.sortbycount then
					return tonumber(o1[3]) > tonumber( o2[3])
				else
					return o1[1] < o2[1]
				end				
			end)
		end
		ImGui.SameLine()
		showgroup = ImGui.Checkbox("Show group", showgroup)
		if not showgroup then
			cres = filterCoin()
		else
			cres = data.coin.results
		end
		
		tsize = ImGui.GetContentRegionAvailVec()

		if ImGui.BeginTable("##currency", 3, flags, tsize) then
			ImGui.TableSetupColumn('Who', ImGuiTableColumnFlags.WidthAuto, -1, 0)
			ImGui.TableSetupColumn('Expac', ImGuiTableColumnFlags.WidthAlwaysAutoResize, 250, 1)
			ImGui.TableSetupColumn('Count', ImGuiTableColumnFlags.WidthAuto, -1, 2)
			ImGui.TableHeadersRow()
			for _, value in ipairs(cres) do
				color = ImVec4(1,1,1,1)
				if tonumber( value[3]) > 450 then
					color = ImVec4(.5,1,.5, 1)
				end
				ImGui.TableNextColumn()
				ImGui.TextColored(color,value[1])
				ImGui.TableNextColumn()
				ImGui.TextColored(color,value[2])
				ImGui.TableNextColumn()
				ImGui.TextColored(color,tostring(value[3]))
			end

			ImGui.EndTable()
		end
		ImGui.EndTabItem()
	end
end
local function bind_cur(...)
	args = {...}
	who = args[1]
	expac = args[2]
	count = args[3]
	table.insert(data.coin.results, {who, expac, count})
	table.sort(data.coin.results, function (o1, o2)	return o1[1] < o2[1] end)
end

local tank      = {["WAR"]=true, ["SHD"]=true, ["PAL"]=true}
function isTank()
    return tank[def.class]
end
local function ui_minimized()
	def.ui.opengui, DRAWGUI = ImGui.Begin('Raid##Min', def.ui.opengui)
    if DRAWGUI then		
		height = 340
		if isTank() then
			height = height + 25
		end
		ImGui.SetWindowSize(100, height)
		-- restore
		if ImGui.Button("Restore", ImVec2(87, 25)) then
			def.ui.minimized = false
		end
		--ImGui.Text("BURNS")
		bsize = ImVec2(80, 80)
		ImageButton("##bon", icons.burnon, bsize, function ()
			eqbc.all("burnallnamed", true)
			eqbc.all("burnalways", true)
		end)
		setToolTip("Burns ON")
		ImageButton("##boff", icons.burnoff, bsize, function ()
			eqbc.all("burnallnamed", false)
			eqbc.all("burnalways", false)
		end)
		setToolTip("Burns Off")
		if isTank() then 
			if ImGui.Button("Tank", ImVec2(87,25)) then
				mq.cmd("/cw mode tank")
			end			
			setToolTip("Mode Tank for this toon only")
		end
		if ImGui.Button("Chase", ImVec2(87,25)) then
			eqbc.bcaa("/cw mode 2")
		end
		setToolTip("Mode Chase")
		if ImGui.Button("Vorpal", ImVec2(87,25)) then
			eqbc.bcaa("/cw mode 3")
		end
		if ImGui.Button("Assist", ImVec2(87,25)) then
			eqbc.bcaa("/cw mode 1")
		end

	end

	ImGui.End()
end

local function ui_tabRandoms()
	if ImGui.BeginTabItem("Randoms") then
		flags = getDefaultTableFlags()
		bsize = ImVec2(50, 25)
		if ImGui.Button("Rules", bsize) then
			str = "Random 1000 to determine loot order"
			mq.cmd("/rs "..str)
		end
		ImGui.SameLine()
		if ImGui.Button("Roll", bsize) then
			mq.cmd("/random 1000")
		end
		ImGui.SameLine()
		if ImGui.Button("Post", bsize) then
			str = "Loot Order: "
			for index, value in ipairs(data.random) do
				str = str .. value[1]
			end
			mq.cmd("/rs "..str)
		end
		ImGui.SameLine()
		if ImGui.Button("Clear", bsize) then
			data.random = {}
		end
		if ImGui.BeginTable("##random", 2, flags, ImGui.GetContentRegionAvailVec()) then
			
			ImGui.TableSetupColumn('Who', ImGuiTableColumnFlags.WidthAuto, -1, 0)
			ImGui.TableSetupColumn('Roll', ImGuiTableColumnFlags.WidthAlwaysAutoResize, 250, 1)
			ImGui.TableHeadersRow()
			for index, value in ipairs(data.random) do
				who = value[1]
				roll = value[2]
				ImGui.TableNextColumn()
				ImGui.Text(who)
				ImGui.TableNextColumn()
				ImGui.Text(roll)
			end
			ImGui.EndTable()
		end
		ImGui.EndTabItem()
	end
end

local function showUi()
	if not def.ui.opengui or mq.TLO.MacroQuest.GameState() ~= 'INGAME' then	 mq.exit() return end
	if def.ui.minimized then ui_minimized()	return	end

    def.ui.opengui, DRAWGUI = ImGui.Begin('RIP Raid Utilities', def.ui.opengui)
    if DRAWGUI then
		ImGui.SetWindowSize(def.ui.width+200, def.ui.height)

		ui_showRaidZone()
		--
		if ImGui.BeginTabBar("tabs", ImGuiTabBarFlags.FittingPolicyResizeDown) then
			if ImGui.BeginTabItem("Settings") then
				--ui_headerControls()
				ui_tableSidebar()
		
		ImGui.SameLine()
				ui_tableSettings()

				ImGui.EndTabItem()
			end
			ui_tabRaids()
			ui_tabRandoms()
			ui_tabGear()
			ui_tabInventory()
			ui_tabCurrency()
			--ui_tabTools()
			ui_tabOptions()

			ImGui.EndTabBar()

		end
        --ImGui.PopStyleColor()
	end
    ImGui.End()
end
local function addFindResult(res)
	--print(res[2] .. tostring(#data.find.items))
	table.insert(data.find.items, res)
	table.sort(data.find.items, function (o1,o2)
		return o1[1] < o2[1]
	end)
end
local function bind_inv(...)
	args = { ... }
	who  = args[1]
	name = args[2]
	count = tonumber(args[3])
	where = args[4]

	for index, value in ipairs(filtertoons) do
		if value == who then
			addFindResult({who,name, count,where})
			return
		end
	end
	
	table.insert(filtertoons, who)
	addFindResult({who,name, count,where})
	
end
local function event_random(line, arg1,arg2)
	table.insert(data.random, { arg1, arg2})
	table.sort(data.random, function (o1, o2)
		return tonumber(o1[2]) > tonumber(o2[2])
	end)
end
local function Init()

	mq.cmd("/plugin mq2status")
	if mq.TLO.Lua.Script("raidutils").Status()=="RUNNING" then
		def.home = mq.TLO.Lua.Dir().."\\raidutils\\"
		def.raids = mq.TLO.Lua.Dir().."\\raidutils\\raids\\"
	elseif mq.TLO.Lua.Script("rip/raidutils").Status()=="RUNNING" then
		def.home = mq.TLO.Lua.Dir().."\\rip\\raidutils"
		def.raids = mq.TLO.Lua.Dir().."\\rip\\"
	end
	createAssets()
	mq.event("gear", "#*#<#1#> #2#: #3#", event_gstatus)
	 mq.event("rn", "#*#A Magic Die is rolled by #1#. It could have been any number from 0 to 1000, but this time it turned up a #2#.#*#", event_random)
	if not mq.TLO.Alias('/cw')() then
		print('/cw alias not present.  Creating /cw alias (single toon cwtn command)') 
		mq.cmd('/noparse /alias /cw /docommand /${Me.Class.ShortName}')
		mq.delay(1000)
		mq.cmd('/bcaa //alias reload')
	end
	if not mq.TLO.Alias('/ru')() then
		print('/ru alias not present.  Creating /ru alias') 
		mq.cmd('/noparse /alias /ru /lua run rip')
		mq.delay(1000)
		mq.cmd('/bcaa //alias reload')
	end
    
	mq.bind("/invresults", bind_inv)
	mq.bind("/curresults", bind_cur)
	mq.bind("/raidutils", bind_ru)

end

local function Main()
	
	mq.imgui.init('Randoms', showUi)

    while true do
        mq.doevents()
        mq.delay(def.pulse)
    end
end

Init()
Main()