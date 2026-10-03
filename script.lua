-- Ventura California Cash Hack - Adaptado a DataManager
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 1. Obtener el CashService real desde la ruta correcta que nos diste
local CashService = ReplicatedStorage.Services.Economy.CashService

if not CashService then
    warn("[ERROR] No se encontró CashService en Services.Economy.")
else
    print("[OK] CashService encontrado.")

    -- Cantidad a añadir por cada trabajo o auto-farm
    local ADD_AMOUNT = 1000000 

    -- 2. Sobrescribir la función 'Give' para que siempre sume más dinero
    -- Guardamos la función original por si acaso, pero la reemplazamos
    local originalGive = CashService.Give
    
    CashService.Give = function(player, amount)
        -- Llamamos a la lógica original primero para mantener la integridad del juego
        if originalGive then
            originalGive(player, amount)
        end
        
        -- AHORA INYECTAMOS NUESTRO DINERO EXTRA
        if player == LocalPlayer then
            -- Usamos el método correcto según el decompilado:
            -- dataManager.Profiles[player].Data.Cash += ADD_AMOUNT
            local profile = CashService.__index and CashService.__index.dataManager and 
                            CashService.__index.dataManager.Profiles[LocalPlayer]
            
            -- Alternativa más directa si no podemos acceder al manager interno fácilmente:
            -- Simplemente forzamos el valor visible Y el interno si es posible
            
            -- Método A: Forzar el leaderstats visible (a veces funciona si el servidor verifica poco)
            local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
            if leaderstats and leaderstats:FindFirstChild("Cash") then
                leaderstats.Cash.Value = leaderstats.Cash.Value + ADD_AMOUNT
            end
            
            -- Método B: Intentar tocar el DataManager directamente si es accesible
            -- Nota: Esto depende de si el manager está expuesto en el cliente
            local dm = ReplicatedStorage.SharedData.DataManager
            if dm and dm.Profiles and dm.Profiles[LocalPlayer] then
                local profileObj = dm.Profiles[LocalPlayer]
                if profileObj and profileObj.Data then
                    profileObj.Data.Cash = profileObj.Data.Cash + ADD_AMOUNT
                    -- Actualizamos también el leaderstats para sincronizar
                    if leaderstats and leaderstats:FindFirstChild("Cash") then
                        leaderstats.Cash.Value = profileObj.Data.Cash
                    end
                end
            end
        end
    end

    print("[HACK] Give sobrescrito. ¡Haz un trabajo para ver el efecto!")

    -- 3. Auto-Farm automático
    task.spawn(function()
        while true do
            task.wait(1) -- Cada 1 segundo
            
            -- Buscar el evento de trabajo
            local giftCash = ReplicatedStorage:FindFirstChild("GiftCash") or 
                             ReplicatedStorage:FindFirstChild("giftcash")
            
            if giftCash then
                giftCash:FireServer()
            else
                -- Si no hay evento público, buscamos en Services
                local servicesFolder = ReplicatedStorage:FindFirstChild("Services")
                if servicesFolder then
                    local economy = servicesFolder:FindFirstChild("Economy")
                    if economy then
                        local remoteEvent = economy:FindFirstChild("GiftCash") or 
                                             economy:FindFirstChild("RemoteEvents"):FindFirstChild("GiftCash")
                        if remoteEvent then
                            remoteEvent:FireServer()
                        end
                    end
                end
            end
        end
    end)
end
