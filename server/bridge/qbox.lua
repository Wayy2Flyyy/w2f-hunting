--- Qbox / QBX (qbx_core) — primary framework bridge. Compatibility layer only; keep QBCore/ESX out of services.

local Bridge = DDHunting.Server.Bridge

Bridge.Qbox = Bridge.Qbox or {}
local Qbox = Bridge.Qbox

local function debugPrint(msg)
    if DDHunting.Config.Main and DDHunting.Config.Main.DebugMode then
        print(('[dd-hunting][qbox] %s'):format(msg))
    end
end

--- Map config-style accounts (ESX-ish names) to qbx money types (cash | bank | crypto).
local function resolveMoneyType(account)
    local a = type(account) == 'string' and account:lower() or 'cash'
    if a == 'money' or a == 'cash' then
        return 'cash'
    end
    if a == 'bank' then
        return 'bank'
    end
    if a == 'black_money' or a == 'dirty' or a == 'markedbills' then
        return 'crypto'
    end
    if a == 'crypto' then
        return 'crypto'
    end
    return 'cash'
end

function Qbox.Init()
    if GetResourceState('qbx_core') ~= 'started' then
        error('[dd-hunting] Config.Framework.Target is "qbox" but qbx_core is not started')
    end
    debugPrint('qbx_core bridge initialized')
end

function Qbox.GetPlayer(source)
    return exports.qbx_core:GetPlayer(source)
end

function Qbox.GetIdentifier(source)
    local player = Qbox.GetPlayer(source)
    if not player then
        return nil
    end
    local pd = player.PlayerData
    if not pd then
        return nil
    end
    return pd.citizenid
end

function Qbox.GetName(source)
    local player = Qbox.GetPlayer(source)
    if not player then
        return nil
    end
    local pd = player.PlayerData
    if not pd then
        return nil
    end
    local info = pd.charinfo
    if type(info) == 'table' then
        local first = info.firstname or info.firstName or ''
        local last = info.lastname or info.lastName or ''
        local full = (('%s %s'):format(first, last)):gsub('^%s+', ''):gsub('%s+$', '')
        if full ~= '' then
            return full
        end
    end
    return pd.name or ('Player %s'):format(source)
end

function Qbox.GetJob(source)
    local player = Qbox.GetPlayer(source)
    if not player then
        return nil
    end
    local pd = player.PlayerData
    local job = pd and pd.job
    if type(job) ~= 'table' then
        return nil
    end

    local grade = job.grade
    if type(grade) == 'table' then
        return {
            name = job.name,
            label = job.label,
            grade = grade.level or grade.grade,
            grade_name = grade.name,
            grade_label = grade.name,
        }
    end

    return {
        name = job.name,
        label = job.label,
        grade = tonumber(grade) or 0,
        grade_name = job.grade_name,
        grade_label = job.grade_label,
    }
end

function Qbox.AddMoney(source, account, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        return false, 'invalid_amount'
    end

    local moneyType = resolveMoneyType(account)
    local ok = exports.qbx_core:AddMoney(source, moneyType, amount, reason or 'dd-hunting')
    if ok then
        return true
    end
    return false, 'add_money_failed'
end

function Qbox.RemoveMoney(source, account, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        return false, 'invalid_amount'
    end

    local moneyType = resolveMoneyType(account)
    local ok = exports.qbx_core:RemoveMoney(source, moneyType, amount, reason or 'dd-hunting')
    if ok then
        return true
    end
    return false, 'insufficient_funds'
end

function Qbox.ShowNotification(source, message, notifyType)
    exports.qbx_core:Notify(source, message, notifyType or 'inform')
end
