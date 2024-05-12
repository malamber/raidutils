local mq        = require("mq")

local my_class  = mq.TLO.Me.Class.ShortName()
local cycle_time = 2000

--[[ 
    Usage:
    on - move good power source in
    off - put a junk source in place
    without any command will toggle the 2
]]

--- Powersource class
PowerSource = {
    ID = 0,
    Name = "",
    Power = 0
}

function PowerSource:new(o)
    o = o or {}

    setmetatable(o, self)
    self.__index = self

    self.Name = o.Name or o
    item =  mq.TLO.FindItem("="..self.Name)
    self.ID = item.ID()   
    self.Power = item.PctPower()
    ItemSlot1  = item.ItemSlot1()
    ItemSlot2  = item.ItemSlot2()
    self.PackSlot = ItemSlot1 - 22
    self.InPackSlot = ItemSlot2 + 1
    return o
end

function PowerSource:activate()
    print("Activating => "..self.Name..":"..self.ID)
    mq.cmdf("/squelch /exchange %d powersource", self.ID)-- ps.name)
    mq.delay(100)
    mq.cmd("/squelch /yes")
    mq.delay(100)
    mq.cmd("/autoinv")
    mq.delay(1000, function() return not mq.TLO.Cursor() end)
end

-- TODO Fix logic t
function PowerSource:power()
    ps = mq.TLO.FindItem("="..self.Name)
    return ps.PctPower()
end

function PowerSource:destroy()
    ps = mq.TLO.FindItem("="..self.Name)
    bag = self.PackSlot
    bagn = self.InPackSlot
end

junksources = {
    "Luclinite Defender Source",
    "Luclinite Convoker Source",
    "Luclinite Attacker Source",
    "Luclinite Mendicant Source",
    "Velium Protector Source",
    "Velium Convoker Source",
    "Velium Assaulter Source",
    "Velium Mendicant Source",
    --"Luclinite Attacker Source",
}

powersources = {
    tank =   {name = "Emberquartz Protector Source", junk = junksources[1]},    
    caster = {name = "Emberquartz Conjuror Source", junk = junksources[2]},
    melee =  {name = "Emberquartz Slayer Source", junk = junksources[3]},
    healer = {name = "Emberquartz Wayfarer Source", junk = junksources[4]},
}
ps = { } -- set in main

function pickupItem(name)
    local item = mq.TLO.FindItem('='..name)
    local itemSlot = item.ItemSlot()
    local itemSlot2 = item.ItemSlot2()
    local packSlot = itemSlot - 22
    local inPackSlot = itemSlot2 + 1
    mq.cmdf('/nomodkey /ctrlkey /itemnotify in pack%s %s leftmouseup', packSlot, inPackSlot)
    mq.delay(2000,function() return mq.TLO.Cursor() end)
end

local function powerLeft(item)
    return item.PctPower()
end

local function findJunkPS()
    for i=1, #junksources do
        src = mq.TLO.FindItem("="..junksources[i])
        if(src()) then return src.Name() end
    end
    return false
end

-- return true if current ps is main src
local function sourceActive()
    local c_ps = mq.TLO.Me.Inventory("powersource")

    if( c_ps == nil or not c_ps.Name()) then return false end

    print("Current Source -> "..c_ps.Name())
    return (c_ps.Name() == ps.name)
end

local function exchange(id)
    while(mq.TLO.Me.Casting() and not my_class=='BRD') do mq.delay(100) end

    mq.cmdf("/exchange %d powersource", id)
    mq.delay(100)
    mq.cmd("/squelch /yes")
    mq.delay(100)
    cur_item = mq.TLO.Cursor()
    -- check the power left and destroy it if power is 0
    if(DEBUG and cur_item and cur_item() == ps.name and powerLeft(cur_item) == 0) then
        print("Destroying ".. ps.name .."(0%)")
        --mq.cmd('/destroy')
    else
        mq.cmd("/autoinv")
        mq.delay(500, function() return not mq.TLO.Cursor() end)
    end
end

local function destroy(item)
    --local slot2 = item.ItemSlot2() + 1
    --local slot1 = item.ItemSlot()
    mq.cmdf('/nomodkey /itemnotify "%s" leftmouseup', item.Name())
    if(mq.TLO.Cursor()) then
        mq.cmd('/destroy')
    end
end

local function activateSource()
    src = mq.TLO.FindItem("="..ps.name)
    if(src and src.Name() == ps.name ) then
        if(powerLeft(src) == 0) then
            print("WARNING::".. ps.name .." is out of power")
            destroy(src)
            return activateSource()
        end
    elseif(not src()) then 
        print(ps.name.. " not found") 
        return false
    end

    id = src.ID()
    print("Activating => "..ps.name.." ("..powerLeft(src).."%)")
    exchange(id)
    return true
end

-- Remove the power source and put it back to inventory
local function deactivateSource()
    if(not ps.junk)then return end

    src = mq.TLO.FindItem("="..ps.junk)
    if(not src()) then 
        print(ps.junk.. " not found")
        return false
    end

    id = src.ID()
    print("Activating => ".. ps.junk.." (JUNK)")
    exchange(id)
end

local function dropItemInSlot(bag, slot)
    mq.cmdf('/nomodkey /itemnotify in pack%s %s leftmouseup', bag, slot)
end

local function isNamed()
    if(mq.TLO.Target() and mq.TLO.Target.Named()) then return true end
    return false
end
local function isRaid()
    if(mq.TLO.Raid.Members() > 0) then return true end
    return false
end

local function bind_cmd(...)
    print("cmd")
    local args = {...}
    if(args[1] == nil ) then return end

    if(args[1] == "on") then
        activateSource()
    elseif(args[1] == "off") then
        deactivateSource()
    elseif(args[1] == "destroy") then
    end
end

local function toggle()
    if(sourceActive()) then deactivateSource() else activateSource() end
    mq.exit()
end

local meleedps  = {["BER"]=true, ["BST"]=true, ["ROG"]=true, ["RNG"]=true, ["BRD"]=true}
local casterdps = {["WIZ"]=true, ["MAG"]=true, ["NEC"]=true, ["ENC"]=true}
local healer    = {["CLR"]=true, ["DRU"]=true, ["SHM"]=true}
local tank      = {["WAR"]=true, ["SHD"]=true, ["PAL"]=true}

local function isTank(cls)
    return tank[cls]
end
local function isCaster(cls)
    return casterdps[cls]
end
local function isMelee(cls)
    return meleedps[cls]
end
local function isHealer(cls)
    return healer[cls]
end

local function Main(args)
    local cmd  = args[1]
    print("Powersource swap")
    
    if(isMelee(my_class)) then
        ps = powersources.melee
    elseif(isHealer(my_class)) then
        ps = powersources.healer
    elseif(isTank(my_class)) then
        ps = powersources.tank
    elseif(isCaster(my_class)) then
        ps = powersources.caster
    else
        mq.exit()
    end

    ps.junk = findJunkPS()
    if(not ps.junk) then 
        print("Unable to find a junk powersource.  Cannot deactivate main source")
    end

    if(cmd) then
        if(cmd == "on") then activateSource()
        elseif(cmd == "off" and ps.junk) then deactivateSource() end
        mq.exit()
    end
    
    toggle()
end

local args = {...}
Main(args)