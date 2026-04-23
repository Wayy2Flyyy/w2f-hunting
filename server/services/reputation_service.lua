local Server = DDHunting.Server
local RepService = {}
Server.Services.Reputation = RepService

local function cfg()
    return DDHunting.Config.Progression or {}
end

local function repCfg()
    return cfg().Reputation or {}
end

local function heatCfg()
    return cfg().Heat or {}
end

local function clamp(value, minVal, maxVal)
    if value < minVal then return minVal end
    if value > maxVal then return maxVal end
    return value
end

function RepService.BuildDefaults()
    local out = {}
    for repType, info in pairs(repCfg().Types or {}) do
        out[repType] = {
            value = tonumber(info.default) or 0,
            lifetimeGain = 0,
            lifetimeLoss = 0,
        }
    end
    return out
end

function RepService.Apply(profile, repType, delta)
    delta = math.floor(tonumber(delta) or 0)
    if delta == 0 then
        return profile.reputation[repType]
    end

    local rep = profile.reputation[repType]
    if not rep then
        rep = { value = 0, lifetimeGain = 0, lifetimeLoss = 0 }
        profile.reputation[repType] = rep
    end

    if repType == 'ranger_heat' then
        local hc = heatCfg()
        rep.value = clamp(rep.value + delta, tonumber(hc.Min) or 0, tonumber(hc.Max) or 100)
    else
        local rc = repCfg()
        rep.value = clamp(rep.value + delta, tonumber(rc.Min) or -2000, tonumber(rc.Max) or 6000)
    end

    if delta > 0 then
        rep.lifetimeGain = rep.lifetimeGain + delta
    else
        rep.lifetimeLoss = rep.lifetimeLoss + math.abs(delta)
    end

    return rep
end

function RepService.GetThresholdTitle(repType, value)
    local thresholds = repCfg().Thresholds and repCfg().Thresholds[repType] or {}
    local title = nil

    for i = 1, #thresholds do
        if value >= thresholds[i].value then
            title = thresholds[i].title
        end
    end

    return title
end

function RepService.ResolveCurrentTitle(profile)
    local rules = cfg().Titles and cfg().Titles.Rules or {}
    local defaultTitle = cfg().Titles and cfg().Titles.Default or 'Rookie Hunter'

    for i = 1, #rules do
        local rule = rules[i]
        local rep = profile.reputation[rule.repType]
        if rep and (rep.value or 0) >= (rule.threshold or 0) then
            return rule.label
        end
    end

    return defaultTitle
end
