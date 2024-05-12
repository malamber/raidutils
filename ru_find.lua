---@diagnostic disable: undefined-field
local mq           = require("mq")
local common       = require("rip.common")
local inv          = require("rip.include.inventory")
local nav          = common.getNav()
local log          = common.getLog()

local def = {
    class = mq.TLO.Me.Class.ShortName(),
    name  = mq.TLO.Me.CleanName(),
    debug = true,
    pulse = 500,
    charm = common.isCC(),
    tank  = common.isTank(),
}
local reportwho = nil
items = {}

local function reportItem(name, count, where)   
    if count <1 then
        return
    end 
    cmd = string.format("/bct %s //invresult %s \"%s\" %d %s",reportwho,def.name, name, count, where)
    mq.cmd(cmd)
end

local function insertItem( item, itemSlot, itemSlot2, where)
    name = item.Name()
    if item.Collectible() then
        where = "collect"
    end
    cnt = mq.TLO.FindItemCount(item.ID())()
    local entry = {item=item, itemslot=itemSlot, itemslot2=itemSlot2>0 and itemSlot2-1 or -1, count = cnt }

    if not items[name] then
        reportItem(name, cnt, where)
        items[name] = entry
    end
end

-- Initialize TSD
function depot_init()
    if mq.TLO.TradeskillDepot.Enabled() then
        if not mq.TLO.TradeskillDepot.ItemsReceived() then
            
            print("Initializing Tradeskill Depot")
            if not mq.TLO.Window('TradeskillDepotWnd').Open() then
                mq.TLO.Window('TradeskillDepotWnd').DoOpen()
                mq.delay(500)
            end
            -- Wait for list to populate
            while not mq.TLO.TradeskillDepot.ItemsReceived() do
                mq.delay(300)
            end
            if mq.TLO.Window('TradeskillDepotWnd').Open() then
                mq.TLO.Window('TradeskillDepotWnd').DoClose()
                mq.delay(500)
            end
        end
    end
end

local function openTSDepot()
    --mq.cmd("/tar bank")
   -- nav.target()
    
   -- mq.cmd('/click right target')
    depot_init()
end
local function sdepo(name)
    local window = mq.TLO.Window("TradeskillDepotWnd/TD_Item_List")

    if not window.Open() then
        window.DoOpen()
        mq.delay(100)
    end
    if not  mq.TLO.TradeskillDepot.ItemsReceived() then
        openTSDepot()
    end
    local itemcount = window.Items()
    for index =1,itemcount do
        local itemname = window.List(index,2)()
        if  string.find(string.lower(itemname), name) then
            count = mq.TLO.TradeskillDepot.FindItemCount("="..itemname)()
            reportItem(itemname, count, "depot")
        end
    end
end

local function insertContainerItems(name, slot, itemSlot, where)
    for j = 1, slot.Container() do
        local containerSlot = slot.Item(j)
        if containerSlot() then
            if  string.find(string.lower(containerSlot.Name()), name) then
                insertItem(containerSlot, itemSlot, j, where)
            end
        end
    end
end

local function isContainer(slot)
    return slot.Container() and slot.Container() > 0
end

local function isMatch(name, p)
    return string.find(string.lower(name), p)
end
local function searchInventory(name)
    
    for i = 23, 34 do
        local slot = mq.TLO.Me.Inventory(i)      

        if isContainer(slot) then
            insertContainerItems(name,slot, i, "inventory")
        elseif slot.ID() ~= nil and string.find(string.lower(slot.Name()), name) then
            insertItem(slot, i, -1, "inventory") -- We have an item in a bag slot
        end
    end

    -- search bank
    for i = 1, 24 do
        local slot = mq.TLO.Me.Bank(i)
        if isContainer(slot) then
            insertContainerItems(name, slot, i, "bank")
        elseif slot.ID() ~= nil and string.find(string.lower(slot.Name()), name)  then
            insertItem(slot, i, -1, "bank") -- We have an item in a bank slot
        end
    end

    for i = 1, 6 do
        local slot = mq.TLO.Me.SharedBank(i)
        if isContainer(slot) then
            insertContainerItems(name, slot, i, "sharedbank")
        elseif slot.ID() ~= nil then
            insertItem(slot, i, -1, "sharedbank") -- We have an item in a sharedbank slot
        end
    end

    for i = 0, 22 do
        local slot = mq.TLO.InvSlot(i).Item
        if slot.ID() ~= nil then
            if isMatch(slot.Name(), name) then                
                insertItem(slot, i, -1, "worn")
            end
            for j=1,8 do
                local augSlot = slot.AugSlot(j).Item
                if augSlot() and isMatch(augSlot.Name(), name) then
                    insertItem(augSlot, i, -1, "aug")
                end
            end
        end
    end

    sdepo(name)
end
local function Main(...)
    args = {...}
    reportwho = args[1] or ""

    if args[2] then
        searchInventory(string.lower(args[2]))
        --searchFor(args[1])
    end
    
end

Main(...)