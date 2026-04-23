local Services = DDHunting.Server.Services

lib.callback.register('dd-hunting:getEnforcementStatus', function(source)
    local summary = Services.Progression.GetSummary(source)
    local rep = summary and summary.reputation or {}

    return {
        rangerHeat = rep.ranger_heat and rep.ranger_heat.value or 0,
        legalRep = rep.legal and rep.legal.value or 0,
        blackMarketRep = rep.black_market and rep.black_market.value or 0,
    }
end)
