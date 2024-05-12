local mq        = require("mq")
local common    = require("rip.common")
local nav       = common.getNav()
local log       = common.getLog()
local ability   = require("rip.include.ability")
local my_class  = mq.TLO.Me.Class.ShortName() 
local my_name   = mq.TLO.Me.CleanName()
local cycle_time = 250

potions = {
    damage = {  "Evocation Focus Draught", "Restless Focus", "Spectral Focus"},
    mana   = { "Crystal Mana Tonic"},
    poison = { "Spider's Bite", },
    agro   = { "Scorpion's Agony"}
    --regen =  {"Elixir of Soothing Ice"}
}

poison = "Consigned Bite of the Shissar"
rank = {"XXII", "XXI", "XX", "XIX", "XVIII", "XVII", "XVI"}

function drink(potion)
    print("Using "..potion.Name())
    if(potion and potion() and potion:isReady()) then
        
        -- mq.cmd("/useitem")
        potion:use()
    end
end

function rogue_summonPoison()
   -- item = ability.getItemBySlot("legs")
    --item:use()
local item = mq.TLO.Me.Inventory("legs")
    --local spell = invitem.Clicky.Spell()
    if item then         
        mq.cmdf('/useitem "%s"', item())
    else
        return
    end
    mq.delay(3 * 1000)

    for _, value in ipairs(rank) do     
        positem =  mq.TLO.FindItem("="..poison.." "..value)--common.getItemByName(poison.." "..value)
        if positem and positem.CanUse() then
            print("using "..poison.." "..value)
            mq.cmd("/useitem \""..poison.." "..value.."\"")
            return
        end
    end

    log.debug("no poisons found")
end

function useFirstPotion(pots)
    for i=1, #pots do
        print("looking for "..pots[i])
        --p = common.getItemByName(pots[i
         local p = mq.TLO.FindItem(pots[i])
       
        if(p) then            
           -- drink(p)
            mq.cmdf('/useitem "%s"', pots[i])
            while(mq.TLO.Me.Casting())do mq.delay(200) end
            return
        end
    end
    print("nothing found")
end

function usePotions()
    my_class = mq.TLO.Me.Class.ShortName()
    if(common.isHealer() or common.isCaster())then
        useFirstPotion(potions.damage)
        useFirstPotion(potions.mana)     
    elseif(common.isMelee() ) then
        useFirstPotion(potions.poison)
    elseif(common.isTank(my_class)) then
        useFirstPotion(potions.agro)
    end    
    --useFirstPotion(potions.regen[1])
end

function Main()
    usePotions()
end

Main()