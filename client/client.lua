local VORPcore = {}
-- Prompts
local BuyPrompt
local TravelPrompt
local ClosedPrompt
local ActiveGroup = GetRandomIntInRange(0, 0xffffff)
local ClosedGroup = GetRandomIntInRange(0, 0xffffff)
-- Jobs
local PlayerJob
local JobName
local JobGrade

TriggerEvent('getCore', function(core)
    VORPcore = core
end)

-- Start Guarma
CreateThread(function()
    Buy()
    Travel()
    Closed()

    while true do
        Wait(0)
        local player = PlayerPedId()
        local coords = GetEntityCoords(player)
        local sleep = true
        local dead = IsEntityDead(player)
        local hour = GetClockHours()

        if not dead then
            for shopId, shopConfig in pairs(Config.shops) do
                if shopConfig.shopHours then
                    -- Using Shop Hours - Shop Closed
                    if hour >= shopConfig.shopClose or hour < shopConfig.shopOpen then
                        if Config.blipOnClosed then
                            if not Config.shops[shopId].Blip and shopConfig.blipOn then
                                AddBlip(shopId)
                            end
                        else
                            if Config.shops[shopId].Blip then
                                RemoveBlip(Config.shops[shopId].Blip)
                                Config.shops[shopId].Blip = nil
                            end
                        end
                        if Config.shops[shopId].Blip then
                            Citizen.InvokeNative(0x662D364ABF16DE2F, Config.shops[shopId].Blip, joaat(Config.BlipColors[shopConfig.blipColorClosed])) -- BlipAddModifier
                        end
                        if shopConfig.NPC then
                            DeleteEntity(shopConfig.NPC)
                            shopConfig.NPC = nil
                        end
                        local pcoords = vector3(coords.x, coords.y, coords.z) -- Player Coords
                        local scoords = vector3(shopConfig.npc.x, shopConfig.npc.y, shopConfig.npc.z) -- Shop Coords
                        local sDistance = #(pcoords - scoords)

                        if (sDistance <= shopConfig.sDistance) then
                            sleep = false
                            local shopClosed = CreateVarString(10, 'LITERAL_STRING', shopConfig.shopName .. _U('closed'))
                            PromptSetActiveGroupThisFrame(ClosedGroup, shopClosed)

                            if Citizen.InvokeNative(0xC92AC953F0A982AE, ClosedPrompt) then -- UiPromptHasStandardModeCompleted
                                Wait(100)
                                VORPcore.NotifyRightTip(shopConfig.shopName .. _U('hours') .. shopConfig.shopOpen .. _U('to') .. shopConfig.shopClose .. _U('hundred'), 4000)
                            end
                        end
                    elseif hour >= shopConfig.shopOpen then
                        -- Using Shop Hours - Shop Open
                        if not Config.shops[shopId].Blip and shopConfig.blipOn then
                            AddBlip(shopId)
                        end
                        if not next(shopConfig.allowedJobs) then
                            if Config.shops[shopId].Blip then
                                Citizen.InvokeNative(0x662D364ABF16DE2F, Config.shops[shopId].Blip, joaat(Config.BlipColors[shopConfig.blipColorOpen])) -- BlipAddModifier
                            end
                            local pcoords = vector3(coords.x, coords.y, coords.z)
                            local scoords = vector3(shopConfig.npc.x, shopConfig.npc.y, shopConfig.npc.z)
                            local sDistance = #(pcoords - scoords)

                            if sDistance <= shopConfig.nDistance then
                                if not shopConfig.NPC and shopConfig.npcOn then
                                    AddNPC(shopId)
                                end
                            else
                                if shopConfig.NPC then
                                    DeleteEntity(shopConfig.NPC)
                                    shopConfig.NPC = nil
                                end
                            end
                            if (sDistance <= shopConfig.sDistance) then
                                sleep = false
                                local shopOpen = CreateVarString(10, 'LITERAL_STRING', shopConfig.promptName)
                                PromptSetActiveGroupThisFrame(ActiveGroup, shopOpen)

                                if Citizen.InvokeNative(0xC92AC953F0A982AE, BuyPrompt) then -- UiPromptHasStandardModeCompleted
                                    TriggerServerEvent('bcc-guarma:BuyTicket', shopConfig.tickets)

                                elseif Citizen.InvokeNative(0xC92AC953F0A982AE, TravelPrompt) then -- UiPromptHasStandardModeCompleted
                                    TriggerServerEvent('bcc-guarma:TakeTicket', shopConfig.tickets)
                                end
                            end
                        else
                            -- Using Shop Hours - Shop Open - Job Locked
                            if Config.shops[shopId].Blip then
                                Citizen.InvokeNative(0x662D364ABF16DE2F, Config.shops[shopId].Blip, joaat(Config.BlipColors[shopConfig.blipColorJob])) -- BlipAddModifier
                            end
                            local pcoords = vector3(coords.x, coords.y, coords.z)
                            local scoords = vector3(shopConfig.npc.x, shopConfig.npc.y, shopConfig.npc.z)
                            local sDistance = #(pcoords - scoords)

                            if sDistance <= shopConfig.nDistance then
                                if not shopConfig.NPC and shopConfig.npcOn then
                                    AddNPC(shopId)
                                end
                            else
                                if shopConfig.NPC then
                                    DeleteEntity(shopConfig.NPC)
                                    shopConfig.NPC = nil
                                end
                            end
                            if (sDistance <= shopConfig.sDistance) then
                                sleep = false
                                local shopOpen = CreateVarString(10, 'LITERAL_STRING', shopConfig.promptName)
                                PromptSetActiveGroupThisFrame(ActiveGroup, shopOpen)

                                if Citizen.InvokeNative(0xC92AC953F0A982AE, BuyPrompt) then -- UiPromptHasStandardModeCompleted
                                    TriggerServerEvent('bcc-guarma:GetPlayerJob')
                                    Wait(200)
                                    if PlayerJob then
                                        if CheckJob(shopConfig.allowedJobs, PlayerJob) then
                                            if tonumber(shopConfig.jobGrade) <= tonumber(JobGrade) then
                                                TriggerServerEvent('bcc-guarma:BuyTicket', shopConfig.tickets)
                                            else
                                                VORPcore.NotifyRightTip(_U('needJob') .. JobName .. " " .. shopConfig.jobGrade, 5000)
                                            end
                                        else
                                            VORPcore.NotifyRightTip(_U('needJob') .. JobName .. " " .. shopConfig.jobGrade, 5000)
                                        end
                                    else
                                        VORPcore.NotifyRightTip(_U('needJob') .. JobName .. " " .. shopConfig.jobGrade, 5000)
                                    end

                                elseif Citizen.InvokeNative(0xC92AC953F0A982AE, TravelPrompt) then -- UiPromptHasStandardModeCompleted
                                    TriggerServerEvent('bcc-guarma:GetPlayerJob')
                                    Wait(200)
                                    if PlayerJob then
                                        if CheckJob(shopConfig.allowedJobs, PlayerJob) then
                                            if tonumber(shopConfig.jobGrade) <= tonumber(JobGrade) then
                                                TriggerServerEvent('bcc-guarma:TakeTicket', shopConfig.tickets)
                                            else
                                                VORPcore.NotifyRightTip(_U('needJob') .. JobName .. " " .. shopConfig.jobGrade, 5000)
                                            end
                                        else
                                            VORPcore.NotifyRightTip(_U('needJob') .. JobName .. " " .. shopConfig.jobGrade, 5000)
                                        end
                                    else
                                        VORPcore.NotifyRightTip(_U('needJob') .. JobName .. " " .. shopConfig.jobGrade, 5000)
                                    end
                                end
                            end
                        end
                    end
                else
                    -- Not Using Shop Hours - Shop Always Open
                    if not Config.shops[shopId].Blip and shopConfig.blipOn then
                        AddBlip(shopId)
                    end
                    if not next(shopConfig.allowedJobs) then
                        if Config.shops[shopId].Blip then
                            Citizen.InvokeNative(0x662D364ABF16DE2F, Config.shops[shopId].Blip, joaat(Config.BlipColors[shopConfig.blipColorOpen])) -- BlipAddModifier
                        end
                        local pcoords = vector3(coords.x, coords.y, coords.z)
                        local scoords = vector3(shopConfig.npc.x, shopConfig.npc.y, shopConfig.npc.z)
                        local sDistance = #(pcoords - scoords)

                        if sDistance <= shopConfig.nDistance then
                            if not shopConfig.NPC and shopConfig.npcOn then
                                AddNPC(shopId)
                            end
                        else
                            if shopConfig.NPC then
                                DeleteEntity(shopConfig.NPC)
                                shopConfig.NPC = nil
                            end
                        end
                        if (sDistance <= shopConfig.sDistance) then
                            sleep = false
                            local shopOpen = CreateVarString(10, 'LITERAL_STRING', shopConfig.promptName)
                            PromptSetActiveGroupThisFrame(ActiveGroup, shopOpen)

                            if Citizen.InvokeNative(0xC92AC953F0A982AE, BuyPrompt) then -- UiPromptHasStandardModeCompleted
                                TriggerServerEvent('bcc-guarma:BuyTicket', shopConfig.tickets)

                            elseif Citizen.InvokeNative(0xC92AC953F0A982AE, TravelPrompt) then -- UiPromptHasStandardModeCompleted
                                TriggerServerEvent('bcc-guarma:TakeTicket', shopConfig.tickets)
                            end
                        end
                    else
                        -- Not Using Shop Hours - Shop Always Open - Job Locked
                        if Config.shops[shopId].Blip then
                            Citizen.InvokeNative(0x662D364ABF16DE2F, Config.shops[shopId].Blip, joaat(Config.BlipColors[shopConfig.blipColorJob])) -- BlipAddModifier
                        end
                        local pcoords = vector3(coords.x, coords.y, coords.z)
                        local scoords = vector3(shopConfig.npc.x, shopConfig.npc.y, shopConfig.npc.z)
                        local sDistance = #(pcoords - scoords)

                        if sDistance <= shopConfig.nDistance then
                            if not shopConfig.NPC and shopConfig.npcOn then
                                AddNPC(shopId)
                            end
                        else
                            if shopConfig.NPC then
                                DeleteEntity(shopConfig.NPC)
                                shopConfig.NPC = nil
                            end
                        end
                        if (sDistance <= shopConfig.sDistance) then
                            sleep = false
                            local shopOpen = CreateVarString(10, 'LITERAL_STRING', shopConfig.promptName)
                            PromptSetActiveGroupThisFrame(ActiveGroup, shopOpen)

                            if Citizen.InvokeNative(0xC92AC953F0A982AE, BuyPrompt) then -- UiPromptHasStandardModeCompleted
                                TriggerServerEvent('bcc-guarma:GetPlayerJob')
                                Wait(200)
                                if PlayerJob then
                                    if CheckJob(shopConfig.allowedJobs, PlayerJob) then
                                        if tonumber(shopConfig.jobGrade) <= tonumber(JobGrade) then
                                            TriggerServerEvent('bcc-guarma:BuyTicket', shopConfig.tickets)
                                        else
                                            VORPcore.NotifyRightTip(_U('needJob') .. JobName .. " " .. shopConfig.jobGrade, 5000)
                                        end
                                    else
                                        VORPcore.NotifyRightTip(_U('needJob') .. JobName .. " " .. shopConfig.jobGrade, 5000)
                                    end
                                else
                                    VORPcore.NotifyRightTip(_U('needJob') .. JobName .. " " .. shopConfig.jobGrade, 5000)
                                end

                            elseif Citizen.InvokeNative(0xC92AC953F0A982AE, TravelPrompt) then -- UiPromptHasStandardModeCompleted
                                TriggerServerEvent('bcc-guarma:GetPlayerJob')
                                Wait(200)
                                if PlayerJob then
                                    if CheckJob(shopConfig.allowedJobs, PlayerJob) then
                                        if tonumber(shopConfig.jobGrade) <= tonumber(JobGrade) then
                                            TriggerServerEvent('bcc-guarma:TakeTicket', shopConfig.tickets)
                                        else
                                            VORPcore.NotifyRightTip(_U('needJob') .. JobName .. " " .. shopConfig.jobGrade, 5000)
                                        end
                                    else
                                        VORPcore.NotifyRightTip(_U('needJob') .. JobName .. " " .. shopConfig.jobGrade, 5000)
                                    end
                                else
                                    VORPcore.NotifyRightTip(_U('needJob') .. JobName .. " " .. shopConfig.jobGrade, 5000)
                                end
                            end
                        end
                    end
                end
            end
        end
        if sleep then
            Wait(1000)
        end
    end
end)

-- Send Player to Destination
RegisterNetEvent('bcc-guarma:SendPlayer', function(location)
    local player = PlayerPedId()
    local destination = location
    local shopConfig = Config.shops[destination]
    DoScreenFadeOut(1000)
    Wait(1000)
    Citizen.InvokeNative(0x1E5B70E53DB661E5, 0, 0, 0, _U('traveling') .. shopConfig.shopName, '', '') -- DisplayLoadingScreens
    Citizen.InvokeNative(0x203BEFFDBE12E96A, player, shopConfig.player.x, shopConfig.player.y, shopConfig.player.z, shopConfig.player.h) -- SetEntityCoordsAndHeading
    FreezeEntityPosition(player, true)
    TaskStandStill(player, -1)
    if destination == 'guarma' then
        Citizen.InvokeNative(0xA657EC9DBC6CC900, 1935063277) -- SetMinimapZone
        Citizen.InvokeNative(0xE8770EE02AEE45C2, 1) -- SetWorldWaterType (1 = Guarma)
        Citizen.InvokeNative(0x74E2261D2A66849A, 1) -- SetGuarmaWorldhorizonActive
    elseif destination == 'stdenis' then
        Citizen.InvokeNative(0x74E2261D2A66849A, 0) -- SetGuarmaWorldhorizonActive
        Citizen.InvokeNative(0xA657EC9DBC6CC900, -1868977180) -- SetMinimapZone
        Citizen.InvokeNative(0xE8770EE02AEE45C2, 0) -- SetWorldWaterType (0 = World)
    end
    Wait(Config.travelTime * 1000)
    ShutdownLoadingScreen()
    FreezeEntityPosition(player, false)
    ClearPedTasksImmediately(player)
    DoScreenFadeIn(2000)
    Wait(1000)
    SetCinematicModeActive(false)
end)

-- Menu Prompts
function Buy()
    local str = _U('buyPrompt')
    BuyPrompt = PromptRegisterBegin()
    PromptSetControlAction(BuyPrompt, Config.keys.buy)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(BuyPrompt, str)
    PromptSetEnabled(BuyPrompt, 1)
    PromptSetVisible(BuyPrompt, 1)
    PromptSetStandardMode(BuyPrompt, 1)
    PromptSetGroup(BuyPrompt, ActiveGroup)
    PromptRegisterEnd(BuyPrompt)
end

function Travel()
    local str = _U('travelPrompt')
    TravelPrompt = PromptRegisterBegin()
    PromptSetControlAction(TravelPrompt, Config.keys.travel)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(TravelPrompt, str)
    PromptSetEnabled(TravelPrompt, 1)
    PromptSetVisible(TravelPrompt, 1)
    PromptSetStandardMode(TravelPrompt, 1)
    PromptSetGroup(TravelPrompt, ActiveGroup)
    PromptRegisterEnd(TravelPrompt)
end

function Closed()
    local str = _U('closedPrompt')
    ClosedPrompt = PromptRegisterBegin()
    PromptSetControlAction(ClosedPrompt, Config.keys.buy)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(ClosedPrompt, str)
    PromptSetEnabled(ClosedPrompt, 1)
    PromptSetVisible(ClosedPrompt, 1)
    PromptSetStandardMode(ClosedPrompt, 1)
    PromptSetGroup(ClosedPrompt, ClosedGroup)
    PromptRegisterEnd(ClosedPrompt)
end

-- Blips
function AddBlip(shopId)
    local shopConfig = Config.shops[shopId]
    shopConfig.Blip = N_0x554d9d53f696d002(1664425300, shopConfig.npc.x, shopConfig.npc.y, shopConfig.npc.z) -- BlipAddForCoords
    SetBlipSprite(shopConfig.Blip, shopConfig.blipSprite, 1)
    SetBlipScale(shopConfig.Blip, 0.2)
    Citizen.InvokeNative(0x9CB1A1623062F402, shopConfig.Blip, shopConfig.blipName) -- SetBlipNameFromPlayerString
end

-- NPCs
function AddNPC(shopId)
    local shopConfig = Config.shops[shopId]
    LoadModel(shopConfig.npcModel)
    local npc = CreatePed(shopConfig.npcModel, shopConfig.npc.x, shopConfig.npc.y, shopConfig.npc.z, shopConfig.npc.h, false, true, true, true)
    Citizen.InvokeNative(0x283978A15512B2FE, npc, true) -- SetRandomOutfitVariation
    SetEntityCanBeDamaged(npc, false)
    SetEntityInvincible(npc, true)
    Wait(500)
    FreezeEntityPosition(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    Config.shops[shopId].NPC = npc
end

function LoadModel(npcModel)
    local model = joaat(npcModel)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
end

-- Check if Player has Job
function CheckJob(allowedJob, playerJob)
    for _, jobAllowed in pairs(allowedJob) do
        JobName = jobAllowed
        if JobName == playerJob then
            return true
        end
    end
    return false
end

RegisterNetEvent('bcc-guarma:SendPlayerJob', function(Job, grade)
    PlayerJob = Job
    JobGrade = grade
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    local player = PlayerPedId()
    PromptDelete(BuyPrompt)
    PromptDelete(TravelPrompt)
    PromptDelete(ClosedPrompt)
    FreezeEntityPosition(player, false)
    ClearPedTasksImmediately(player)

    for _, shopConfig in pairs(Config.shops) do
        if shopConfig.Blip then
            RemoveBlip(shopConfig.Blip)
        end
        if shopConfig.NPC then
            DeleteEntity(shopConfig.NPC)
            shopConfig.NPC = nil
        end
    end
end)
