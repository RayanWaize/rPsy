local ESX = nil
local societyPsyMoney = nil
local allRegisterClient = {}
local allAction = { 
    action = {'Le faire entrer', 'Fin du rdv', 'Refuser'},
    index = 1
}

Citizen.CreateThread(function()
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
	while ESX == nil do Citizen.Wait(100) end

    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end

    ESX.PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
end)

local function rPsyKeyboard(TextEntry, ExampleText, MaxStringLenght)
    AddTextEntry('FMMC_KEY_TIP1', TextEntry)
    blockinput = true
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLenght)
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do 
        Wait(0)
    end 
        
    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Wait(500)
        blockinput = false
        return result
    else
        Wait(500)
        blockinput = false
        return nil
    end
end


function menuPsy()
    local menuP = RageUI.CreateMenu("Psychologue", " ")
    local menuS = RageUI.CreateSubMenu(menuP, "Psychologue", " ")
    RageUI.Visible(menuP, not RageUI.Visible(menuP))

    while menuP do
        Citizen.Wait(0)
        RageUI.IsVisible(menuP, true, true, true, function()

            RageUI.Separator("Que voulez-vous faire ?")

            RageUI.ButtonWithStyle("Facture",nil, {RightLabel = "→→"}, true, function(Hovered, Active, Selected)
                if Selected then
                    local player, distance = ESX.Game.GetClosestPlayer()
                    local amount = rPsyKeyboard("Montant de la facture ?", "", 10)
                    if tonumber(amount) then
                        if player ~= -1 and distance <= 3.0 then
                            TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(player), 'society_psy', ('Psychologue'), tonumber(amount))
                            TriggerEvent('esx:showAdvancedNotification', 'Fl~g~ee~s~ca ~g~Bank', 'Facture envoyée : ', 'Vous avez envoyé une facture d\'un montant de : ~g~'..amount..'$', 'CHAR_BANK_FLEECA', 9)
                        else
                            ESX.ShowNotification("~r~Probleme~s~: Aucuns joueurs proche")
                        end
                    else
                        ESX.ShowNotification("~r~Probleme~s~: Montant invalide")
                    end
                end
            end)

            RageUI.ButtonWithStyle("Ouvrir/Fermer le cabinet",nil, {RightLabel = "→→"}, true, function(Hovered, Active, Selected)
                if Selected then
                    TriggerServerEvent("rPsy:setStatePsyIG")
                end
            end)
            

            RageUI.Separator("~y~Salle d'attente")

            RageUI.ButtonWithStyle("Gestion des patients",nil, {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                if Selected then
                    ESX.TriggerServerCallback('rPsy:getAllRegister', function(result)
                        allRegisterClient = result
                    end)
                end
            end, menuS)

        end)


        RageUI.IsVisible(menuS, true, true, true, function()

            RageUI.Separator("Que voulez-vous faire ?")

            if #allRegisterClient == 0 then
                RageUI.Separator("")
                RageUI.Separator("~r~La salle d'attente est vide")
                RageUI.Separator("")

            else

                for k,v in pairs(allRegisterClient) do
                    RageUI.List(v.numberRegister.." - "..v.namePlayer, allAction.action, allAction.index , nil, {RightLabel = ""}, true, function(Hovered, Active, Selected, Index)                     
                        if (Selected) then
                            if Index == 1 then
                                TriggerServerEvent('rPsy:setStateEnter', k)
                            elseif Index == 2 then
                                TriggerServerEvent('rPsy:setStateEnd', k)
                            elseif Index == 3 then
                                TriggerServerEvent('rPsy:setStateRefuse', k)
                            end

                            ESX.TriggerServerCallback('rPsy:getAllRegister', function(result)
                                allRegisterClient = result
                            end)
                        end
                        allAction.index = Index;
                    end)
                end
            end
        end)
        if not RageUI.Visible(menuP) and not RageUI.Visible(menuS) then
            menuP = RMenu:DeleteType("menuP", true)
        end
    end
end


Keys.Register('F6', 'Psy', 'Ouvrir le menu Psychologue', function()
	if ESX.PlayerData.job and ESX.PlayerData.job.name == 'psy' then
        ESX.TriggerServerCallback('rPsy:getAllRegister', function(result)
            allRegisterClient = result
        end)
    	menuPsy()
	end
end)


function menuRdvPsy(ifMe)
    local menuP = RageUI.CreateMenu("Psychologue", " ")
    RageUI.Visible(menuP, not RageUI.Visible(menuP))

    while menuP do
        Citizen.Wait(0)
        RageUI.IsVisible(menuP, true, true, true, function()

            RageUI.Separator("Que voulez-vous faire ?")

            RageUI.ButtonWithStyle("S'inscrire",nil, {RightLabel = "→→"}, true, function(Hovered, Active, Selected)
                if Selected then
                    TriggerServerEvent("rPsy:registerWithPsy")
                end
            end)

            RageUI.Separator("~y~Cabinet")

            RageUI.ButtonWithStyle("Rentrer chez le psy",nil, {RightLabel = "→→→"}, ifMe, function(Hovered, Active, Selected)
                if Selected then
                    SetEntityCoords(PlayerPedId(), Config.posGotoCabinet)
                    RageUI.CloseAll()
                end
            end)

        end)
        if not RageUI.Visible(menuP) then
            menuP = RMenu:DeleteType("menuP", true)
        end
    end
end


Citizen.CreateThread(function()
    while true do
        local Timer = 500
        local plyPos = GetEntityCoords(PlayerPedId())
        local dist = #(plyPos-Config.posMenuRdv)
        if dist <= 10.0 then
         Timer = 0
         DrawMarker(22, Config.posMenuRdv, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.45, 0.45, 0.45, 255, 0, 0, 255, 55555, false, true, 2, false, false, false, false)
        end
         if dist <= 3.0 then
            Timer = 0
                RageUI.Text({ message = "Appuyez sur ~y~[E]~s~ pour prendre rendez-vous chez le psy", time_display = 1 })
            if IsControlJustPressed(1,51) then
                ESX.TriggerServerCallback('rPsy:getIfPsyState', function(ifHere)
                    if ifHere then
                        ESX.TriggerServerCallback('rPsy:getIfMyTurn', function(result)
                            menuRdvPsy(result)
                        end)
                    else
                        ESX.ShowNotification("~r~Probleme~s~: Le Cabinet est fermé")
                    end
                end)
                
            end
         end
    Citizen.Wait(Timer)
 end
end)

Citizen.CreateThread(function()
    while true do
        local Timer = 500
        local plyPos = GetEntityCoords(PlayerPedId())
        local dist = #(plyPos-Config.posExit)
        if dist <= 10.0 then
         Timer = 0
         DrawMarker(22, Config.posExit, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.45, 0.45, 0.45, 255, 0, 0, 255, 55555, false, true, 2, false, false, false, false)
        end
        if dist <= 1.0 then
            Timer = 0
                RageUI.Text({ message = "Appuyez sur ~y~[E]~s~ pour quitter le cabinet", time_display = 1 })
            if IsControlJustPressed(1,51) then
                SetEntityCoords(PlayerPedId(), Config.posGotoExit)
            end
        end
    Citizen.Wait(Timer)
 end
end)

function menuBoss()
    local menuBossP = RageUI.CreateMenu("Actions Patron", "Psychologue")
    RageUI.Visible(menuBossP, not RageUI.Visible(menuBossP))
    while menuBossP do
        Wait(0)
        RageUI.IsVisible(menuBossP, true, true, true, function()

            if societyPsyMoney ~= nil then
                RageUI.Separator("~o~Argent société:~s~ ~g~"..societyPsyMoney.."$")
            end

            RageUI.ButtonWithStyle("Retirer argent de société",nil, {RightLabel = "→→"}, true, function(Hovered, Active, Selected)
                if Selected then
                    local amount = rPsyKeyboard("Montant", "", 10)
                    amount = tonumber(amount)
                    if amount == nil then
                        RageUI.Popup({message = "Montant invalide"})
                    else
                        TriggerServerEvent('esx_society:withdrawMoney', 'psy', amount)
                        refreshPsyMoney()
                    end
                end
            end)

            RageUI.ButtonWithStyle("Déposer argent de société",nil, {RightLabel = "→→"}, true, function(Hovered, Active, Selected)
                if Selected then
                    local amount = rPsyKeyboard("Montant", "", 10)
                    amount = tonumber(amount)
                    if amount == nil then
                        RageUI.Popup({message = "Montant invalide"})
                    else
                        TriggerServerEvent('esx_society:depositMoney', 'psy', amount)
                        refreshPsyMoney()
                    end
                end
            end)

           RageUI.ButtonWithStyle("Accéder aux actions de Management",nil, {RightLabel = "→→"}, true, function(Hovered, Active, Selected)
                if Selected then
                    TriggerEvent('esx_society:openBossMenu', 'psy', function(data, menu)
                        menu.close()
                    end, {wash = false})
                    RageUI.CloseAll()
                end
            end)
        end)
        if not RageUI.Visible(menuBossP) then
            menuBossP = RMenu:DeleteType("menuBossP", true)
        end
    end
end

function refreshPsyMoney()
    if ESX.PlayerData.job ~= nil and ESX.PlayerData.job.grade_name == 'boss' then
        ESX.TriggerServerCallback('esx_society:getSocietyMoney', function(money)
            UpdateSocietyPsyMoney(money)
        end, ESX.PlayerData.job.name)
    end
end

function UpdateSocietyPsyMoney(money)
    societyPsyMoney = ESX.Math.GroupDigits(money)
end

Citizen.CreateThread(function()
    while true do
        local Timer = 500
        local plyPos = GetEntityCoords(PlayerPedId())
        local dist = #(plyPos-Config.posMenuBoss)
        if ESX.PlayerData.job and ESX.PlayerData.job.name == 'psy' and ESX.PlayerData.job.grade_name == 'boss' then
        if dist <= 10.0 then
         Timer = 0
         DrawMarker(22, Config.posMenuBoss, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.45, 0.45, 0.45, 255, 0, 0, 255, 55555, false, true, 2, false, false, false, false)
        end
         if dist <= 3.0 then
            Timer = 0
                RageUI.Text({ message = "Appuyez sur ~y~[E]~s~ pour accéder aux actions patron", time_display = 1 })
            if IsControlJustPressed(1,51) then
                refreshPsyMoney()
                menuBoss()
            end
         end
        end
    Citizen.Wait(Timer)
 end
end)


function menuCoffre()
    local menuP = RageUI.CreateMenu("Coffre", "Psychologue")
        RageUI.Visible(menuP, not RageUI.Visible(menuP))
            while menuP do
            Citizen.Wait(0)
            RageUI.IsVisible(menuP, true, true, true, function()

                RageUI.Separator("~b~↓ Objet ↓")

                    RageUI.ButtonWithStyle("Retirer",nil, {RightLabel = "→→"}, true, function(Hovered, Active, Selected)
                        if Selected then
                            RageUI.CloseAll()
                            menuCoffreRetirer()
                        end
                    end)
                    
                    RageUI.ButtonWithStyle("Déposer",nil, {RightLabel = "→→"}, true, function(Hovered, Active, Selected)
                        if Selected then
                            RageUI.CloseAll()
                            menuCoffreDeposer()
                        end
                    end)
                end)
            if not RageUI.Visible(menuP) then
            menuP = RMenu:DeleteType("menuP", true)
        end
    end
end

Citizen.CreateThread(function()
    while true do
        local Timer = 500
        local plyPos = GetEntityCoords(PlayerPedId())
        local dist = #(plyPos-Config.posCoffre)
        if ESX.PlayerData.job and ESX.PlayerData.job.name == 'psy' then
        if dist <= 10.0 then
         Timer = 0
         DrawMarker(22, Config.posCoffre, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.45, 0.45, 0.45, 255, 0, 0, 255, 55555, false, true, 2, false, false, false, false)
        end
         if dist <= 3.0 then
            Timer = 0
                RageUI.Text({ message = "Appuyez sur ~y~[E]~s~ pour accéder au coffre", time_display = 1 })
            if IsControlJustPressed(1,51) then
                menuCoffre()
            end
         end
        end
    Citizen.Wait(Timer)
 end
end)

function menuCoffreRetirer()
    local menuCoffre = RageUI.CreateMenu("Coffre", "Psychologue")
    ESX.TriggerServerCallback('rPsy:getStockItems', function(items) 
    RageUI.Visible(menuCoffre, not RageUI.Visible(menuCoffre))
        while menuCoffre do
            Citizen.Wait(0)
                RageUI.IsVisible(menuCoffre, true, true, true, function()
                        for k,v in pairs(items) do 
                            if v.count > 0 then
                            RageUI.ButtonWithStyle(v.label, nil, {RightLabel = v.count}, true, function(Hovered, Active, Selected)
                                if Selected then
                                    local count = rPsyKeyboard("Combien ?", "", 2)
                                    TriggerServerEvent('rPsy:getStockItem', v.name, tonumber(count))
                                    RageUI.CloseAll()
                                end
                            end)
                        end
                    end
                end, function()
                end)
            if not RageUI.Visible(menuCoffre) then
            menuCoffre = RMenu:DeleteType("Coffre", true)
        end
    end
     end)
end


function menuCoffreDeposer()
    local StockPlayer = RageUI.CreateMenu("Coffre", "Voici votre ~y~inventaire")
    ESX.TriggerServerCallback('rPsy:getPlayerInventory', function(inventory)
        RageUI.Visible(StockPlayer, not RageUI.Visible(StockPlayer))
    while StockPlayer do
        Citizen.Wait(0)
            RageUI.IsVisible(StockPlayer, true, true, true, function()
                for i=1, #inventory.items, 1 do
                    if inventory ~= nil then
                         local item = inventory.items[i]
                            if item.count > 0 then
                                    RageUI.ButtonWithStyle(item.label, nil, {RightLabel = item.count}, true, function(Hovered, Active, Selected)
                                            if Selected then
                                            local count = rPsyKeyboard("Combien ?", '' , 8)
                                            TriggerServerEvent('rPsy:putStockItems', item.name, tonumber(count))
                                            RageUI.CloseAll()
                                        end
                                    end)
                                end
                            else
                                RageUI.Separator('Chargement en cours')
                            end
                        end
                    end, function()
                    end)
                if not RageUI.Visible(StockPlayer) then
                StockPlayer = RMenu:DeleteType("Coffre", true)
            end
        end
    end)
end


function menuGarage()
    local menuGarageP = RageUI.CreateMenu("Garage", "Psychologue")
        RageUI.Visible(menuGarageP, not RageUI.Visible(menuGarageP))
            while menuGarageP do
            Citizen.Wait(0)
            RageUI.IsVisible(menuGarageP, true, true, true, function()

                RageUI.Separator("~r~↓ Rangement ↓")

                    RageUI.ButtonWithStyle("Ranger la voiture", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
                        if Selected then
                            local veh, dist4 = ESX.Game.GetClosestVehicle()
                            if dist4 < 4 then
                                DeleteEntity(veh)
                                RageUI.CloseAll()
                            end
                        end
                    end)

                    RageUI.Separator("~u~↓ Véhicule disponible ↓")

                    for k,v in pairs(Config.garagePsy) do
                        RageUI.ButtonWithStyle(v.label, nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
                            if Selected then
                                spawnuniCarPsy(v.model)
                                RageUI.CloseAll()
                            end
                        end)
                    end

                end)
            if not RageUI.Visible(menuGarageP) then
            menuGarageP = RMenu:DeleteType("menuGarageP", true)
        end
    end
end

Citizen.CreateThread(function()
    while true do
        local Timer = 500
        local plyPos = GetEntityCoords(PlayerPedId())
        local dist = #(plyPos-Config.posGarage)
        if ESX.PlayerData.job and ESX.PlayerData.job.name == 'psy' then
        if dist <= 10.0 then
         Timer = 0
         DrawMarker(22, Config.posGarage, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.45, 0.45, 0.45, 255, 0, 0, 255, 55555, false, true, 2, false, false, false, false)
        end
         if dist <= 3.0 then
            Timer = 0
                RageUI.Text({ message = "Appuyez sur ~y~[E]~s~ pour accéder au garage", time_display = 1 })
            if IsControlJustPressed(1,51) then
                menuGarage()
            end
         end
        end
    Citizen.Wait(Timer)
 end
end)


function spawnuniCarPsy(car)
    local carhash = GetHashKey(car)
    RequestModel(car)
    while not HasModelLoaded(car) do
        RequestModel(car)
        Citizen.Wait(0)
    end
    local vehicle = CreateVehicle(carhash, Config.posSpawnCar, true, false)
    local plaque = "psy"..math.random(1,9)
    SetVehicleNumberPlateText(vehicle, plaque)
    SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
end