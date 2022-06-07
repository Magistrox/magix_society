RegisterServerEvent("magix_society:sendbill")
AddEventHandler("magix_society:sendbill", function(qty, closestPlayer)
  local _source = source

  TriggerEvent("vorp:getCharacter",source,function(user)
        if user.job == "unemployed" then
            TriggerClientEvent("vorp:TipRight", _source, "Vous n'avez pas de job.", 3000)
        else
            local identifierplayer = GetPlayerIdentifier(closestPlayer, steam)
            
            exports.ghmattimysql:execute("INSERT INTO facture (identifier, sender, montant, entreprise) VALUES (@identifier, @sender, @montant, @entreprise)", {
                ['identifier'] = identifierplayer,
                ['sender'] = user.identifier,
                ['montant'] = qty,
                ['entreprise'] = user.job
            })
        end
  end)
end)

RegisterServerEvent('magix_society:voirfacture')
AddEventHandler('magix_society:voirfacture', function()
	local _source = source

    TriggerEvent("vorp:getCharacter",source,function(user)
        exports.ghmattimysql:execute('SELECT * FROM facture WHERE identifier = @identifier', {['identifier'] = user.identifier}, function(result)
            local facture = {}

            if result[1] then 
                for i=1, #result, 1 do
                    table.insert(facture, {
                        montant = result[i].montant,
                        entreprise = result[i].entreprise,
                        id = result[i].id
                    })
                    TriggerClientEvent('magix_society:findfacture', _source, facture)
                end
            else            
                for i=1, #result, 1 do
                    table.insert(menu, {
                        AucuneFacture = ""
                    })
                end

                TriggerClientEvent('magix_society:findfacture', _source, facture)
            end
        end)
    end)
end)

RegisterServerEvent('magix_society:paybill')
AddEventHandler('magix_society:paybill', function(id, montant)
    TriggerEvent("vorp:getCharacter",source,function(user)
        local getidentifier = user.identifier
        local getmoney = user.money

        if getmoney >= montant then
            TriggerEvent("vorp:removeMoney", source, 0, montant);
            TriggerClientEvent("vorp:TipRight", source, "Vous avez payé votre facture.", 3000)
            
            Citizen.Wait(100)

           exports.ghmattimysql:execute('SELECT * FROM facture WHERE identifier = @identifier AND id = @id', {['identifier'] = getidentifier, ['id'] = id}, function(result)
                local entreprise_facture = result[1].entreprise

                exports.ghmattimysql:execute('SELECT * FROM society WHERE entreprise = @entreprise', {['entreprise'] = entreprise_facture}, function(result)
                    local money_entreprise = result[1].solde
                    local nouveau = money_entreprise + montant

                    exports.ghmattimysql:execute("UPDATE society SET solde = @solde WHERE entreprise = @entreprise", {
                        ['solde'] = nouveau,
                        ['entreprise'] = entreprise_facture
                    })

                    exports.ghmattimysql:execute("DELETE FROM facture WHERE identifier = @identifier AND id = @id", {
                        ['identifier'] = getidentifier,
                        ['id'] = id
                    })
                end)
            end)
        else
            TriggerClientEvent("vorp:TipRight", source, "Vous n\'avez pas assez d'argent.", 3000)
        end
    end)
end)

RegisterServerEvent('magix_society:entreprise')
AddEventHandler('magix_society:entreprise', function()
	local _source = source

    TriggerEvent("vorp:getCharacter",source,function(user)
        exports.ghmattimysql:execute('SELECT * FROM society WHERE entreprise = @entreprise', {['entreprise'] = user.job}, function(result)
            local menu = {}

            if user.jobGrade == '2' then
                for i=1, #result, 1 do
                    table.insert(menu, {
                        entreprise = result[i].entreprise,
                        solde = result[i].solde
                })
                end

                TriggerClientEvent('magix_society:menuentreprise', _source, menu)
            else
                TriggerClientEvent('magix_society:closemenu', _source)
                TriggerClientEvent("vorp:TipRight", _source, "Vous n\'êtes pas patron.", 3000)
            end
        end)
    end)
end)

RegisterServerEvent('magix_society:banqueentreprise')
AddEventHandler('magix_society:banqueentreprise', function()
	local _source = source

    TriggerEvent("vorp:getCharacter",source,function(user)
        exports.ghmattimysql:execute('SELECT * FROM society WHERE entreprise = @entreprise', {['entreprise'] = user.job}, function(result)
            local menu = {}

            if user.jobGrade == '2' then
                for i=1, #result, 1 do
                    table.insert(menu, {
                        entreprise = result[i].entreprise,
                        solde = result[i].solde,
                        NotBoss = "OK"
                })
                end

                TriggerClientEvent('magix_society:menubanqueentreprise', _source, menu)
            else
                for i=1, #result, 1 do
                    table.insert(menu, {
                        NotBoss = "NotBoss"
                })
                end

                TriggerClientEvent('magix_society:menubanqueentreprise', _source, menu)
                TriggerClientEvent("vorp:TipRight", _source, "Vous n\'êtes pas patron.", 3000)
            end
        end)
    end)
end)

RegisterServerEvent('magix_society:entreprisewithdraw')
AddEventHandler('magix_society:entreprisewithdraw', function(solde, nom)

    exports.ghmattimysql:execute("UPDATE society SET solde = @solde WHERE entreprise = @entreprise", {
        ['solde'] = 0,
        ['entreprise'] = nom
    })

    TriggerEvent("vorp:addMoney", source, 0, solde);
    TriggerClientEvent("vorp:TipRight", source, "Vous avez retiré tous l'argent. ("..solde.."$)", 3000)
end)

RegisterServerEvent('magix_society:entreprisehire')
AddEventHandler('magix_society:entreprisehire', function(closestPlayer, nom)
    TriggerEvent("vorp:setJob", closestPlayer, nom)
    TriggerClientEvent("vorp:TipRight", source, "Vous avez engager une personne.", 3000)
    TriggerClientEvent("vorp:TipRight", closestPlayer, "Vous êtes maintenant "..nom..".", 3000)
end)

RegisterServerEvent('magix_society:entrepriseout')
AddEventHandler('magix_society:entrepriseout', function(closestPlayer)
    TriggerEvent("vorp:setJob", closestPlayer, "unemployed")
    TriggerClientEvent("vorp:TipRight", source, "Vous avez virer une personne.", 3000)
    TriggerClientEvent("vorp:TipRight", closestPlayer, "Vous avez été viré.", 3000)
end)