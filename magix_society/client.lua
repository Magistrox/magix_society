local keys = { ['G'] = 0x760A9C6F, ['S'] = 0xD27782E3, ['W'] = 0x8FD015D8, ['H'] = 0x24978A28, ['G'] = 0x5415BE48, ["ENTER"] = 0xC7B5340A, ['E'] = 0xDFF812F9,["BACKSPACE"] = 0x156F7119 }

local facturelist = {}
local entreprise = {}
local banqueentreprise = {}
local label 
local prompts = GetRandomIntInRange(0, 0xffffff)

Citizen.CreateThread(function()
    Citizen.Wait(500)
    local str = "Appuyer"
	openmenu = PromptRegisterBegin()
	PromptSetControlAction(openmenu, 0x760A9C6F)
	str = CreateVarString(10, 'LITERAL_STRING', str)
	PromptSetText(openmenu, str)
	PromptSetEnabled(openmenu, 1)
	PromptSetVisible(openmenu, 1)
	PromptSetStandardMode(openmenu,1)
    PromptSetHoldMode(openmenu, 1)
	PromptSetGroup(openmenu, prompts)
	Citizen.InvokeNative(0xC5F428EE08FA7F2C,openmenu,true)
	PromptRegisterEnd(openmenu)
end)

function GetClosestPlayer()
    local players, closestDistance, closestPlayer = GetActivePlayers(), -1, -1
    local playerPed, playerId = PlayerPedId(), PlayerId()
    local coords, usePlayerPed = coords, false
    
    if coords then
        coords = vector3(coords.x, coords.y, coords.z)
    else
        usePlayerPed = true
        coords = GetEntityCoords(playerPed)
    end
    
    for i=1, #players, 1 do
        local tgt = GetPlayerPed(players[i])

        if not usePlayerPed or (usePlayerPed and players[i] ~= playerId) then

            local targetCoords = GetEntityCoords(tgt)
            local distance = #(coords - targetCoords)

            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = players[i]
                closestDistance = distance
            end
        end
    end
    return closestPlayer, closestDistance
end


RegisterNetEvent('magix_society:sendbill')
AddEventHandler('magix_society:sendbill', function(source, closestPlayer)
    
    local myInput = {
        type = "enableinput", -- dont touch
        inputType = "input", -- or text area for sending messages
        button = "Envoyé", -- button name
        placeholder = "Insérer le montant", --placeholdername
        style = "block", --- dont touch
        attributes = {
            inputHeader = "Montant de la facture", -- header
            type = "number", -- inputype text, number,date.etc if number comment out the pattern
            pattern = "[0-9]{1,20}", -- regular expression validated for only numbers "[0-9]", for letters only [A-Za-z]+   with charecter limit  [A-Za-z]{5,20}     with chareceter limit and numbers [A-Za-z0-9]{5,}
            title = "Maximum 20 chiffres", -- if input doesnt match show this message
            style = "border-radius: 10px; background-color: ; border:none;", -- style  the inptup
        }
    }
    TriggerEvent("vorpinputs:advancedInput", json.encode(myInput),function(result)
        local qty = tonumber(result)
    
        if qty ~= nil and qty ~= 0 and qty > 0 then
            TriggerServerEvent("magix_society:sendbill", qty, closestPlayer)
        else
            TriggerEvent("vorp:TipRight", "Montant introuvable", 3000)
        end
    end)
end)

RegisterCommand('facture', function()

    local firstVec = GetEntityCoords(PlayerPedId())
    local closestPlayer = GetClosestPlayer()
    local dist = #(firstVec - closestPlayer) -- Do not use Z

    if dist < 1 then
        TriggerEvent("vorp:TipBottom", "Aucun joueur proche.", 3000)
    else
        TriggerEvent("magix_society:sendbill", source, GetPlayerServerId(closestPlayer))
    end

end)

Citizen.CreateThread(function()
    WarMenu.CreateMenu('voirfacture', "Mes factures")
    WarMenu.SetSubTitle('voirfacture', 'Voir vos factures')

    while true do
        if WarMenu.IsMenuOpened('voirfacture') then
            for i = 1, #facturelist do
				if WarMenu.Button(""..facturelist[i].entreprise..": "..facturelist[i].montant.."$") then
                    local id = facturelist[i].id
                    local montant = facturelist[i].montant

                    TriggerServerEvent("magix_society:paybill", id, montant)
                    
                    WarMenu.CloseMenu()
                end
			end
            WarMenu.Display()
		end
        Citizen.Wait(0)
    end
end)

RegisterCommand('voirfacture', function()
    TriggerServerEvent("magix_society:voirfacture")
    Citizen.Wait(300)
    WarMenu.OpenMenu('voirfacture')
end)

RegisterNetEvent('magix_society:closemenu')
AddEventHandler('magix_society:closemenu', function()
    Citizen.Wait(300)
	WarMenu.CloseMenu()
end)

RegisterNetEvent('magix_society:findfacture')
AddEventHandler('magix_society:findfacture', function(facture)
	facturelist = facture
end)

RegisterNetEvent('magix_society:menuentreprise')
AddEventHandler('magix_society:menuentreprise', function(menu)
	entreprise = menu
end)

RegisterNetEvent('magix_society:menubanqueentreprise')
AddEventHandler('magix_society:menubanqueentreprise', function(menu)
	banqueentreprise = menu
end)

RegisterCommand('entreprise', function()
    TriggerServerEvent("magix_society:entreprise")
    Citizen.Wait(300)
    WarMenu.OpenMenu('entreprise')
end)

Citizen.CreateThread(function()
    WarMenu.CreateMenu('entreprise', "Mon entreprise")
    WarMenu.SetSubTitle('entreprise', 'Choisir un option')

    while true do
        if WarMenu.IsMenuOpened('entreprise') then
            for i = 1, #entreprise do

                if WarMenu.Button("Engager") then

                    local firstVec = GetEntityCoords(PlayerPedId())
                    local closestPlayer = GetClosestPlayer()
                    local dist = #(firstVec - closestPlayer) -- Do not use Z
                
                    if dist < 1 then
                        TriggerEvent("vorp:TipBottom", "Aucun joueur proche.", 3000)
                    else
                        local nom = entreprise[i].entreprise
                        TriggerServerEvent("magix_society:entreprisehire", GetPlayerServerId(closestPlayer), nom)
                    end
                    WarMenu.CloseMenu()
                end
                
                if WarMenu.Button("Virer") then

                    local firstVec = GetEntityCoords(PlayerPedId())
                    local closestPlayer = GetClosestPlayer()
                    local dist = #(firstVec - closestPlayer) -- Do not use Z
                
                    if dist < 1 then
                        TriggerEvent("vorp:TipBottom", "Aucun joueur proche.", 3000)
                    else
                        TriggerServerEvent("magix_society:entrepriseout", GetPlayerServerId(closestPlayer))
                    end
                    WarMenu.CloseMenu()
                end

			end
            WarMenu.Display()
		end
        Citizen.Wait(0)
    end
end)

Citizen.CreateThread(function()
    WarMenu.CreateMenu('banqueentreprise', "Compte de banque")
    WarMenu.SetSubTitle('banqueentreprise', 'Gestion du compte')

    while true do
        if WarMenu.IsMenuOpened('banqueentreprise') then
            for i = 1, #banqueentreprise do
                if banqueentreprise[i].NotBoss == "OK" then
				    if WarMenu.Button("Solde: "..banqueentreprise[i].solde.."$") then end
                    
                    if WarMenu.Button("Retirer tous l'argent") then
                        local solde = banqueentreprise[i].solde
                        local nom = banqueentreprise[i].entreprise

                        TriggerServerEvent("magix_society:entreprisewithdraw", solde, nom)
                        WarMenu.CloseMenu()
                    end
                else
                    WarMenu.CloseMenu()
                end
			end
            WarMenu.Display()
		end
        Citizen.Wait(0)
    end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)

        local firstVec = GetEntityCoords(PlayerPedId())
        local secondVec = vector3(vector3(-304.913, 775.1826, 118.70))

        local dist = #(firstVec.xy - secondVec.xy) -- Do not use Z

        if dist < 1 then

            local label  = CreateVarString(10, 'LITERAL_STRING', "Compte entreprise")
            PromptSetActiveGroupThisFrame(prompts, label)

            if IsControlJustReleased(0, 0x760A9C6F) then
                TriggerServerEvent("magix_society:banqueentreprise")
                Citizen.Wait(500)
                WarMenu.OpenMenu('banqueentreprise')            
            end
        end
    end
end)

