DDHunting.Client.Systems.ContractsUI = DDHunting.Client.Systems.ContractsUI or {}
local ContractsUI = DDHunting.Client.Systems.ContractsUI

local BOARDS = {
    { key = 'ranger', label = 'Ranger Board' },
    { key = 'trapper', label = 'Trapper Board' },
    { key = 'trophy', label = 'Trophy Board' },
    { key = 'black_market', label = 'Black Market Board' },
}

local function rewardLine(rewards)
    if not rewards then return 'No reward data' end
    return ('Payout $%s | XP %s | Rep %s'):format(rewards.payout or 0, rewards.xp or 0, rewards.rep or 0)
end

function ContractsUI.OpenBoard(boardKey)
    local contracts = lib.callback.await('dd-hunting:getContractBoard', false, boardKey)
    if type(contracts) ~= 'table' then
        lib.notify({ title = 'Contracts', description = 'No board data available.', type = 'error' })
        return
    end

    local options = {
        {
            title = 'Refresh Board',
            description = 'Request a board refresh (cooldown applies).',
            icon = 'rotate',
            onSelect = function()
                TriggerServerEvent('dd-hunting:sv:refreshContractBoard', boardKey)
            end
        }
    }

    for i = 1, #contracts do
        local c = contracts[i]
        options[#options + 1] = {
            title = ('%s [%s]'):format(c.label, c.tier),
            description = ('%sx %s (%s) | %s'):format(c.quantity, c.item, c.species, rewardLine(c.rewards)),
            icon = 'file-signature',
            onSelect = function()
                TriggerServerEvent('dd-hunting:sv:acceptContract', boardKey, c.id)
            end
        }
    end

    if #options == 0 then
        options[#options + 1] = {
            title = 'No contracts available',
            description = 'Board refresh is in progress.',
            disabled = true,
        }
    end

    lib.registerContext({ id = ('dd_hunting_board_%s'):format(boardKey), title = ('%s Contracts'):format(boardKey), options = options })
    lib.showContext(('dd_hunting_board_%s'):format(boardKey))
end

function ContractsUI.OpenBoardSelector()
    local options = {}

    for i = 1, #BOARDS do
        local board = BOARDS[i]
        options[#options + 1] = {
            title = board.label,
            icon = 'clipboard',
            onSelect = function()
                ContractsUI.OpenBoard(board.key)
            end,
        }
    end

    lib.registerContext({ id = 'dd_hunting_contract_board_selector', title = 'Contract Boards', options = options })
    lib.showContext('dd_hunting_contract_board_selector')
end

function ContractsUI.OpenActiveContracts()
    local active = lib.callback.await('dd-hunting:getActiveContracts', false)
    local options = {}

    for i = 1, #(active or {}) do
        local c = active[i]
        options[#options + 1] = {
            title = ('%s [%s]'):format(c.label, c.tier),
            description = ('Need %sx %s | Expires: %s'):format(c.quantity, c.item, os.date('%X', c.expiresAt or os.time())),
            icon = 'list-check',
            menu = ('dd_hunting_active_contract_%s'):format(c.id),
        }

        lib.registerContext({
            id = ('dd_hunting_active_contract_%s'):format(c.id),
            title = c.label,
            menu = 'dd_hunting_active_contracts',
            options = {
                {
                    title = 'Turn In',
                    icon = 'hand-holding-dollar',
                    onSelect = function()
                        TriggerServerEvent('dd-hunting:sv:turnInContract', c.id)
                    end
                },
                {
                    title = 'Abandon',
                    icon = 'xmark',
                    onSelect = function()
                        TriggerServerEvent('dd-hunting:sv:abandonContract', c.id)
                    end
                }
            }
        })
    end

    if #options == 0 then
        options[1] = { title = 'No active contracts', disabled = true }
    end

    lib.registerContext({ id = 'dd_hunting_active_contracts', title = 'Active Contracts', options = options })
    lib.showContext('dd_hunting_active_contracts')
end

RegisterCommand('huntcontracts', function()
    ContractsUI.OpenBoardSelector()
end, false)

RegisterCommand('huntactivecontracts', function()
    ContractsUI.OpenActiveContracts()
end, false)
