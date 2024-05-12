---@diagnostic disable: undefined-field

local mq           = require("mq")
local def = {
    class = mq.TLO.Me.Class.ShortName(),
    name  = mq.TLO.Me.CleanName(),
}
report = ""
coin = {
    "Laurion Inn Voucher",
    "Shalowain's Private Reserve",
    "Spiritual Medallions"
}
local function getCurrency()
    for index, value in ipairs(coin) do
        c = mq.TLO.Me.AltCurrency(value)()
        mq.cmd("/bct "..report.." //curresults "..def.name.." \""..value.."\" ".. c)
    end
end
local function Main(...)
    args = {...}
    report = args[1]
    getCurrency()
end

Main(...)