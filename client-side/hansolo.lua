local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")

--[ CONNECTION ]----------------------------------------------------------------------------------------------------------------

pDS = Tunnel.getInterface("ldn-drugs-sell")

--[ VARIABLES ]----------------------------------------------------------------------------------------------------------------

local blips = true
local inService = false
local check = 0
local percent = 0

--[ VARIABLES | SERVICE ]----------------------------------------------------------------------------------------------------------------

local serviceX = -455.01
local serviceY = -1689.59
local serviceZ = 19.29

-- -455.01,-1689.59,19.29

--[ VARIABLES | DELIVERY ]----------------------------------------------------------------------------------------------------------------

local deliverys = {
	[1] = { ['x'] = 880.08, ['y'] = -205.67, ['z'] = 71.98, ['x2'] = 880.32, ['y2'] = -205.41, ['z2'] = 71.98, ['h'] = 339.12 },
	[2] = { ['x'] = 1247.01, ['y'] = -350.13, ['z'] = 69.21, ['x2'] = 1247.24, ['y2'] = -349.89, ['z2'] = 69.21, ['h'] = 166.60 }, 
	[3] = { ['x'] = -262.99, ['y'] = 202.66, ['z'] = 85.37, ['x2'] = -262.85, ['y2'] = 202.64, ['z2'] = 85.37, ['h'] = 358.96 }, 
	[4] = { ['x'] = -1402.74, ['y'] = -451.92, ['z'] = 34.49, ['x2'] = -1402.71, ['y2'] = -452.02, ['z2'] = 34.49, ['h'] = 31.33 }, 
	[5] = { ['x'] = -1776.29, ['y'] = -670.98, ['z'] = 10.38, ['x2'] = -1776.53, ['y2'] = -670.91, ['z2'] = 10.4, ['h'] = 140.06 }, 
	[6] = { ['x'] = -3077.97, ['y'] = 658.96, ['z'] = 11.67, ['x2'] = -3077.8, ['y2'] = 658.99, ['z2'] = 11.67, ['h'] = 131.39 }, 
	[7] = { ['x'] = -794.24, ['y'] = 351.63, ['z'] = 88.0, ['x2'] = -794.35, ['y2'] = 351.88, ['z2'] = 88.0, ['h'] = 179.27 } 
}

--[ START DELIVERY | THREAD ]----------------------------------------------------------------------------------------------------------------

Citizen.CreateThread(function()
	while true do
		local idle = 1000
		local ped = PlayerPedId()
		if not inService then
			local x,y,z = table.unpack(GetEntityCoords(ped))
			local distance = Vdist(serviceX,serviceY,serviceZ,x,y,z)
			if distance <= 10.1 then
				idle = 5
				DrawMarker(21,serviceX,serviceY,serviceZ-0.6,0,0,0,0.0,0,0,0.5,0.5,0.4,178,34,34,50,0,0,0,1)
				if distance <= 3.1 then
					if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), serviceX,serviceY,serviceZ, true ) <= 3.1  then
						DrawText3D(serviceX,serviceY,serviceZ, "PRESSIONE ~r~E~w~ PARA INICIAR A ~r~ENTREGA~w~ DE ~r~DROGAS~w~")
					end
					if IsControlJustPressed(0,38) and not inService then
						if pDS.checkPermission() then
							inService = true
							check = math.random(#deliverys)
							makeBlipsServices(deliverys,check)
							TriggerEvent("Notify","sucesso","Uma <b>entrega</b> de drogas foi <b>encontrada</b>!",8000)
							TriggerEvent("Notify","importante","O <b>endereço</b> de destino das <b>entregas</b> foram repassados em seu <b>GPS</b>.",8000)
            else 
              TriggerEvent("Notify","negado","Acredito que você esteja no local errado!")
            end
					end
				end
			end
		end
		Citizen.Wait(idle)
	end
end)

--[ DELIVERY ORDER | THREAD ]----------------------------------------------------------------------------------------------------------------

Citizen.CreateThread(function()
	while true do
		local idle = 1000
		local ped = PlayerPedId()
		if inService then
			local x,y,z = table.unpack(GetEntityCoords(ped))
			local bowz,cdz = GetGroundZFor_3dCoord(deliverys[check].x,deliverys[check].y,deliverys[check].z)
			local distance = GetDistanceBetweenCoords(deliverys[check].x,deliverys[check].y,cdz,x,y,z,true)

			if distance <= 10.1 then
				idle = 5
				DrawMarker(1,deliverys[check].x,deliverys[check].y,deliverys[check].z-1.0,0,0,0,0.0,0,0,1.2,1.2,1.2,255,255,255,50,0,0,0,1)
				if distance <= 3.1 then
					if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), deliverys[check].x,deliverys[check].y,deliverys[check].z, true ) <= 3.1  then
						DrawText3D(deliverys[check].x,deliverys[check].y,deliverys[check].z, "PRESSIONE ~r~E~w~ PARA ENTREGAR AS ~r~DROGAS~w~")
					end
					if IsControlJustPressed(0,38) then

						SetEntityCoords(ped,deliverys[check].x2,deliverys[check].y2,deliverys[check].z2)
						SetEntityHeading(ped,deliverys[check].h)

						if pDS.startPayments() then

							percent = math.random(1,100)

							if percent >= 1 and percent <= 70 then
								pDS.callPolice()
								TriggerEvent("Notify","aviso","Transuentes acionaram a <b>polícia</b> ao local.")
							end

							pDS.setTimeout()

							RemoveBlip(blips)
							check = math.random(#deliverys)
							makeBlipsServices(deliverys,check)

							TriggerEvent("Notify","importante","Vá até o <b>endereço</b> de <b>destino</b> repassado em seu <b>GPS</b>.",8000)
						end
					end
				end
			end
		end
		Citizen.Wait(idle)
	end
end)

--[ CANCEL DELIVERY | THREAD ]----------------------------------------------------------------------------------------------------------------

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(5)
    if inService and IsControlJustPressed(0,121) then
      TriggerEvent("Notify","importante","Vá até o <b>endereço</b> de <b>destino</b> repassado em seu <b>GPS</b>.")
      elseif IsControlJustPressed(0,168) then
        inService = false
        RemoveBlip(blips)
        TriggerEvent("Notify","aviso","Você <b>finalizou</b> a entrega de <b>drogas</b>.")
		end
	end
end)

--[ TEXT | FUNCTION ]----------------------------------------------------------------------------------------------------------------

function DrawText3D(x,y,z, text)
  local onScreen,_x,_y=World3dToScreen2d(x,y,z)
  local px,py,pz=table.unpack(GetGameplayCamCoords())
  
  SetTextScale(0.28, 0.28)
  SetTextFont(4)
  SetTextProportional(1)
  SetTextColour(255, 255, 255, 215)
  SetTextEntry("STRING")
  SetTextCentre(1)
  AddTextComponentString(text)
  DrawText(_x,_y)
  local factor = (string.len(text)) / 370
  DrawRect(_x,_y+0.0125, 0.005+ factor, 0.03, 41, 11, 41, 68)
end

--[ BLIP | FUNCTION ]----------------------------------------------------------------------------------------------------------------

function makeBlipsServices(deliverys,check)
	blips = AddBlipForCoord(deliverys[check].x,deliverys[check].y,deliverys[check].z)
	SetBlipSprite(blips,1)
	SetBlipColour(blips,5)
	SetBlipScale(blips,0.4)
	SetBlipAsShortRange(blips,false)
	SetBlipRoute(blips,true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Ilegal | Entrega de Drogas")
	EndTextCommandSetBlipName(blips)
end