local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
local Tools = module("vrp","lib/Tools")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

--[ CONNECTION ]----------------------------------------------------------------------------------------------------------------

pDS = {}
Tunnel.bindInterface("ldn-drugs-sell",pDS)

local idgens = Tools.newIDGenerator()

--[ VARIABLES ]-----------------------------------------------------------------------------------------------------------------

local blips = {}
local ammount = {}

--[ DELIVERY ORDER | FUNCTION (CHECK PERMISSION) ]-------------------------------------------------------------------------------------------------

function pDS.checkPermission()
  local source = source
  local user_id = vRP.getUserId(source)
  return not (vRP.hasPermission(user_id,"policia.permissao") or vRP.hasPermission(user_id,"paramedico.permissao"))
end

--[ DELIVERY ORDER | FUNCTION (START PAYMENTS) ]-------------------------------------------------------------------------------------------------

function pDS.startPayments()
  local source = source
  local user_id = vRP.getUserId(source)
  local ped = GetPlayerPed(source)
  if ammount[source] == nil then
    ammount[source] = math.random(2,10)
  end
	if user_id then
		if vRP.tryGetInventoryItem(user_id,"metanfetamina",ammount[source]) or vRP.tryGetInventoryItem(user_id,"cocaina",ammount[source]) or vRP.tryGetInventoryItem(user_id,"marijuana",ammount[source]) then
			TriggerClientEvent("progress",source,2000,"Ilegal | Vendendo algumas drogas")
			FreezeEntityPosition(ped, true)
			vRPclient._playAnim(source,false,{{"timetable@jimmy@doorknock@","knockdoor_idle"}},true)

			Citizen.Wait(2000)
			vRPclient._stopAnim(source,false)
			FreezeEntityPosition(ped, false)

			local price = math.random(440,600)
			vRP.giveInventoryItem(user_id,"dinheiro-sujo",parseInt(price*ammount[source]))
			TriggerClientEvent("Notify",source,"sucesso","Você entregou <b>x"..ammount[source].." drogas</b>, recebendo <b>$"..vRP.format(parseInt(price*ammount[source])).." dólares-sujos</b>.")
			ammount[source] = nil
			return true
		else
			TriggerClientEvent("Notify",source,"negado","Você precisa de <b>"..ammount[source].."x drogas</b>.",8000)
		end
	end
end


--[ POLICE CALL | FUNCTION ]-------------------------------------------------------------------------------------------------

function pDS.callPolice()
	local source = source
	local user_id = vRP.getUserId(source)
	local x,y,z = vRPclient.getPosition(source)
	local identity = vRP.getUserIdentity(user_id)
	if user_id then
		local police = vRP.getUsersByPermission("policia-ptr.permissao")
		for l,w in pairs(police) do
			local player = vRP.getUserSource(parseInt(w))
			if player then
				async(function()
					local id = idgens:gen()
					blips[id] = vRPclient.addBlip(player,x,y,z,10,84,"Ocorrência | Tráfico de Drogas",0.5,false)
					vRPclient._playSound(player,"CONFIRM_BEEP","HUD_MINI_GAME_SOUNDSET")
					TriggerClientEvent('chatMessage',player,"911",{64,64,255},"Recebemos uma denuncia de tráfico de drogas, verifique o ocorrido.")
					SetTimeout(20000,function() vRPclient.removeBlip(player,blips[id]) idgens:free(id) end)
				end)
			end
		end
	end
end