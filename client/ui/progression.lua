DDHunting.Client.Systems.ProgressionUI = DDHunting.Client.Systems.ProgressionUI or {}
local ProgressionUI = DDHunting.Client.Systems.ProgressionUI
local State = DDHunting.Client.State

local function repLine(label, value, tier)
    local tierText = tier and (' (%s)'):format(tier) or ''
    return ('%s: %s%s'):format(label, value or 0, tierText)
end

local function getReputationOptions(p)
    local rep = p.reputation or {}

    return {
        {
            title = 'Legal Hunter Rep',
            description = repLine('Value', rep.legal and rep.legal.value, rep.legal and rep.legal.label),
            icon = 'shield-halved',
            disabled = true,
        },
        {
            title = 'Trapper Rep',
            description = repLine('Value', rep.trapper and rep.trapper.value, rep.trapper and rep.trapper.label),
            icon = 'feather',
            disabled = true,
        },
        {
            title = 'Trophy Rep',
            description = repLine('Value', rep.trophy and rep.trophy.value, rep.trophy and rep.trophy.label),
            icon = 'trophy',
            disabled = true,
        },
        {
            title = 'Black Market Rep',
            description = repLine('Value', rep.black_market and rep.black_market.value, rep.black_market and rep.black_market.label),
            icon = 'skull',
            disabled = true,
        },
        {
            title = 'Ranger Heat',
            description = repLine('Heat', rep.ranger_heat and rep.ranger_heat.value, nil),
            icon = 'fire',
            disabled = true,
        },
    }
end

local function getMasteryOptions(p)
    local options = {}
    local mastery = p.mastery or {}

    for i = 1, math.min(6, #mastery) do
        local row = mastery[i]
        options[#options + 1] = {
            title = ('%s (Rank %s)'):format(row.species, row.masteryRank),
            description = ('Kills %s | Clean %s | Trophy %.1f | Weight %.1f'):format(
                row.kills,
                row.cleanKills,
                row.bestTrophy or 0,
                row.bestWeight or 0
            ),
            icon = 'paw',
            disabled = true,
        }
    end

    if #options == 0 then
        options[#options + 1] = {
            title = 'No mastery data yet',
            description = 'Harvest species to build mastery records.',
            icon = 'circle-info',
            disabled = true,
        }
    end

    return options
end

function ProgressionUI.OpenOverview()
    local p = State.Progression

    local options = {
        {
            title = ('%s (Level %s)'):format(p.currentTitle or 'Rookie Hunter', p.level),
            description = ('XP %s / %s | Skill Points %s'):format(p.xp, p.xpToNext, p.skillPoints),
            icon = 'chart-simple',
            disabled = true,
        },
        {
            title = 'Session Totals',
            description = ('Hunts %s | Clean %s | Sales %s'):format(
                (p.totals and p.totals.hunts) or 0,
                (p.totals and p.totals.cleanKills) or 0,
                (p.totals and p.totals.sales) or 0
            ),
            icon = 'clipboard-list',
            disabled = true,
        },
    }

    local repOptions = getReputationOptions(p)
    for i = 1, #repOptions do
        options[#options + 1] = repOptions[i]
    end

    for branchKey, rank in pairs(p.branches or {}) do
        options[#options + 1] = {
            title = ('%s (%s)'):format(branchKey, rank),
            description = p.skillPoints > 0 and 'Spend 1 skill point to rank up.' or 'No skill points available.',
            icon = 'tree',
            disabled = p.skillPoints <= 0,
            onSelect = function()
                TriggerServerEvent('dd-hunting:sv:spendSkillPoint', branchKey)
            end
        }
    end

    local masteryOptions = getMasteryOptions(p)
    for i = 1, #masteryOptions do
        options[#options + 1] = masteryOptions[i]
    end

    lib.registerContext({
        id = 'dd_hunting_progression_overview',
        title = 'Hunter Progression',
        options = options
    })

    lib.showContext('dd_hunting_progression_overview')
end

RegisterCommand('huntskills', function()
    ProgressionUI.OpenOverview()
end, false)

RegisterNetEvent('dd-hunting:cl:progressionStateUpdated', function(payload)
    if payload and payload.skillPoints and payload.skillPoints > 0 then
        lib.notify({
            title = 'Hunter Progression',
            description = ('You have %s unspent skill points. Use /huntskills.'):format(payload.skillPoints),
            type = 'inform'
        })
    end
end)
