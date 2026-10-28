-- ==== BENCH HUB V2 (ALL PARTS 1-16) ====
local P  = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local REP = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local TS = game:GetService("TeleportService")
local CG = game:GetService("CoreGui")
local LP = P.LocalPlayer

-- Ремоуты (строго из слитых скриптов)
local GE = REP:WaitForChild("GrabEvents")
local SNO = GE:WaitForChild("SetNetworkOwner")
local CL  = GE:WaitForChild("CreateGrabLine")
local DL  = GE:WaitForChild("DestroyGrabLine")
local EL  = GE:WaitForChild("ExtendGrabLine")
local CE = REP:WaitForChild("CharacterEvents")
local RR = CE:WaitForChild("RagdollRemote")
local ST = CE:WaitForChild("Struggle")
local MT = REP:WaitForChild("MenuToys")
local SP = MT:WaitForChild("SpawnToyRemoteFunction")
local DT = MT:WaitForChild("DestroyToy")
local SE = REP:WaitForChild("PlayerEvents"):WaitForChild("StickyPartEvent")
local BE = REP:WaitForChild("BombEvents"):WaitForChild("BombExplode")

-- Библиотека Rayfield (с защитой от блокировки)
local Rayfield
local lib_urls = {
    "https://raw.githubusercontent.com/Footagesus/Rayfield/main/source.lua",
    "https://sirius.menu/rayfield"
}
for _, url in ipairs(lib_urls) do
    local ok, res = pcall(function()
        local src = game:HttpGet(url)
        if not src or src == "" then return nil end
        return loadstring(src)()
    end)
    if ok and type(res) == "table" and res.CreateWindow then
        Rayfield = res
        break
    end
end
if not Rayfield then
    warn("[bench] CRITICAL: Could not load UI.")
    return
end

local W = Rayfield:CreateWindow({
    Name = "bench",
    LoadingTitle = "bench",
    LoadingSubtitle = "loading",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

local TabTgt  = W:CreateTab("Target")
local TabBlob = W:CreateTab("Blobman")
local TabDef  = W:CreateTab("Defense")
local TabVis  = W:CreateTab("Visual")
local TabSrv  = W:CreateTab("Server")
local TabMisc = W:CreateTab("Misc")

local S = { target = nil }

-- === ХЕЛПЕРЫ ===
local function chr() return LP.Character end
local function hrp() local c = chr(); return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = chr(); return c and c:FindFirstChildOfClass("Humanoid") end
local function thrp(p) local c = p and p.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function thum(p) local c = p and p.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function inv() return WS:FindFirstChild(LP.Name .. "SpawnedInToys") end
local function zer(b) if b then b.AssemblyLinearVelocity = Vector3.zero; b.AssemblyAngularVelocity = Vector3.zero end end
local function sno(b) if b then pcall(function() SNO:FireServer(b, b.CFrame) end) end end
local function line(b) if b then pcall(function() CL:FireServer(b, b.CFrame) end) end end 
local function kline(b) if b then pcall(function() DL:FireServer(b) end) end end
local function owned(b) local o = b and b:FindFirstChild("PartOwner"); return o and o.Value == LP.Name end
local function vis(on)
    local c = chr(); if not c then return end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BasePart") then d.LocalTransparencyModifier = on and 0 or 1 end
    end
end
local function plist()
    local t = { "None" }
    for _, p in ipairs(P:GetPlayers()) do if p ~= LP then table.insert(t, p.DisplayName .. " (" .. p.Name .. ")") end end
    return t
end

-- ФИКС CALLBACK ERROR (Универсальный парсер)
local function getStr(v)
    local s = v
    if type(v) == "table" then 
        s = v[1] or next(v) 
        if type(s) == "table" then s = s[1] or next(s) end
    end
    if type(s) ~= "string" then return nil end
    if s == "" or s == "None" then return nil end
    local match = s:match("%((.-)%)")
    if match then s = match end
    return s
end

local function pick(v)
    local s = getStr(v)
    if s then return P:FindFirstChild(s) end
    return nil
end

local function notify(t, d, dur)
    pcall(function()
        Rayfield:Notify({ Title = tostring(t or "bench"), Content = tostring(d or ""), Duration = dur or 3 })
    end)
end

-- ==========================================
-- ЧАСТЬ 1: TARGET SELECT
-- ==========================================
TabTgt:CreateSection("Target")
local targetDrop = TabTgt:CreateDropdown({
    Name = "Target", Options = plist(), CurrentOption = "None",
    MultipleOptions = false, Flag = "targetPick",
    Callback = function(v) 
        pcall(function() S.target = pick(v) end)
    end,
})
P.PlayerAdded:Connect(function() task.defer(function() pcall(function() targetDrop:Refresh(plist(), true) end) end) end)
P.PlayerRemoving:Connect(function(p)
    if S.target == p then S.target = nil end
    task.defer(function() pcall(function() targetDrop:Refresh(plist(), true) end) end)
end)

-- ==========================================
-- ЧАСТЬ 2: MERCURY KICK (Самый мощный)
-- ==========================================
TabTgt:CreateSection("Mercury Kick")
local Kick = { on = false, x = 0, y = 20, z = 5 }

TabTgt:CreateSlider({
    Name = "Kick Height (Y)", Range = { 0, 50 }, Increment = 1, Suffix = "",
    CurrentValue = 20, Flag = "kickH",
    Callback = function(v) Kick.y = v end,
})

local kickToggle = TabTgt:CreateToggle({
    Name = "Enable Kick", CurrentValue = false, Flag = "kickT",
    Callback = function(on)
        Kick.on = on
        if not on and S.target then
            local t = thrp(S.target)
            if t then
                local bp = t:FindFirstChild("KickHoldBP")
                local bg = t:FindFirstChild("KickHoldBG")
                if bp then bp:Destroy() end
                if bg then bg:Destroy() end
            end
        end
    end,
})

TabTgt:CreateKeybind({
    Name = "Kick Bind", CurrentKeybind = "F", HoldToInteract = false, Flag = "kickB",
    Callback = function()
        local next = not Kick.on
        pcall(function() kickToggle:Set(next) end)
    end,
})

RS.Heartbeat:Connect(function()
    if not Kick.on or not S.target then return end
    local me = hrp()
    local t = thrp(S.target)
    local th = thum(S.target)
    
    if me and t and th and th.Health > 0 then
        -- Физика из Меркури
        t.AssemblyLinearVelocity = Vector3.zero
        t.AssemblyAngularVelocity = Vector3.zero
        
        if (t.Position - me.Position).Magnitude > 30 then
            me.CFrame = CFrame.new(t.Position) * CFrame.new(0, -15, 0)
            zer(me)
        end
        
        local bp = t:FindFirstChild("KickHoldBP") or Instance.new("BodyPosition", t)
        bp.Name = "KickHoldBP"
        bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bp.P = 50000
        bp.D = 100
        bp.Position = me.Position + Vector3.new(Kick.x, Kick.y, Kick.z)
        
        local bg = t:FindFirstChild("KickHoldBG") or Instance.new("BodyGyro", t)
        bg.Name = "KickHoldBG"
        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bg.P = 50000
        bg.D = 100
        bg.CFrame = CFrame.new(t.Position, t.Position + me.CFrame.LookVector)
        
        pcall(function()
            SNO:FireServer(t, t.CFrame)
            DL:FireServer(t)
        end)
    end
end)

-- ==========================================
-- ЧАСТЬ 3: GHOST GRAB (NeoLose)
-- ==========================================
TabTgt:CreateSection("Ghost Grab")
local Ghost = { on = false, clone = nil, bp = nil, bg = nil }
local function ghostStop()
    Ghost.on = false; vis(true)
    if Ghost.bp then Ghost.bp:Destroy(); Ghost.bp = nil end
    if Ghost.bg then Ghost.bg:Destroy(); Ghost.bg = nil end
    if Ghost.clone then Ghost.clone:Destroy(); Ghost.clone = nil end
    if S.target then kline(thrp(S.target)) end
    local h = hum(); if h then WS.CurrentCamera.CameraSubject = h end
end
local function ghostStart()
    if not chr() or not hrp() then return end
    Ghost.on = true; vis(false)
    task.spawn(function()
        while Ghost.on do
            RS.RenderStepped:Wait()
            local t = thrp(S.target); local th = thum(S.target)
            if not t or not th or th.Health <= 0 then
                if Ghost.clone then Ghost.clone:Destroy(); Ghost.clone = nil end
            else
                if not Ghost.clone or not Ghost.clone.Parent then
                    local ok, c = pcall(function()
                        LP.Character.Archivable = true
                        local k = LP.Character:Clone()
                        LP.Character.Archivable = false
                        for _, d in ipairs(k:GetDescendants()) do
                            if d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end
                        end
                        k.Name = "BenchGhost"; k.Parent = WS; return k
                    end)
                    if ok then
                        Ghost.clone = c
                        local ch = c:FindFirstChildOfClass("Humanoid")
                        if ch then WS.CurrentCamera.CameraSubject = ch end
                    end
                end
                if Ghost.clone and Ghost.clone:FindFirstChild("HumanoidRootPart") then
                    Ghost.clone.HumanoidRootPart.CFrame = CFrame.new(t.Position + Vector3.new(0, 8, 20))
                end
                local me = hrp()
                if me then
                    sno(t); line(t)
                    th.PlatformStand = true; th.Sit = true
                    if not Ghost.bp or Ghost.bp.Parent ~= t then
                        if Ghost.bp then Ghost.bp:Destroy() end
                        if Ghost.bg then Ghost.bg:Destroy() end
                        Ghost.bp = Instance.new("BodyPosition", t)
                        Ghost.bp.P = 1e6; Ghost.bp.D = 500
                        Ghost.bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        Ghost.bg = Instance.new("BodyGyro", t)
                        Ghost.bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                        Ghost.bg.P = 50000; Ghost.bg.D = 100
                    end
                    Ghost.bp.Position = me.Position + Vector3.new(0, 12, -4)
                    Ghost.bg.CFrame = me.CFrame
                    zer(t)
                end
            end
        end
    end)
end
local ghostToggle = TabTgt:CreateToggle({
    Name = "Ghost Grab", CurrentValue = false, Flag = "ghostGrab",
    Callback = function(on) if on and S.target then ghostStart() else ghostStop() end end,
})

-- ==========================================
-- ЧАСТЬ 4: SNOWBALL RAGDOLL (NeoLose)
-- ==========================================
TabTgt:CreateSection("Snowball")
local Snow = { on = false }
TabTgt:CreateToggle({
    Name = "Snowball Ragdoll", CurrentValue = false, Flag = "snowT",
    Callback = function(on)
        Snow.on = on
        if not on then return end
        task.spawn(function()
            while Snow.on do
                task.wait(0.1)
                local t = thrp(S.target); local me = hrp(); local i = inv()
                if t and me and i then
                    local s = i:FindFirstChild("BallSnowball")
                    if not s then
                        if LP:FindFirstChild("CanSpawnToy") and LP.CanSpawnToy.Value then
                            pcall(function() SP:InvokeServer("BallSnowball", me.CFrame * CFrame.new(0, 10, 20), Vector3.zero) end)
                        end
                        task.wait(0.15)
                    else
                        local sn = s:FindFirstChild("SoundPart")
                        if sn then
                            sno(sn); task.wait(0.05)
                            sn.CFrame = t.CFrame; task.wait(0.05)
                            pcall(function()
                                BE:FireServer({
                                    Radius = 0, Color = Color3.new(0,0,0), TimeLength = 0,
                                    Model = s, Type = "SnowPoof", ExplodesByFire = false,
                                    MaxForcePerStudSquared = 0, Hitbox = sn, ImpactSpeed = 0,
                                    ExplodesByPointy = false, DestroysModel = true, PositionPart = sn,
                                }, Vector3.zero)
                            end)
                            task.wait(0.15)
                        end
                    end
                end
            end
        end)
    end,
})

-- ==========================================
-- ЧАСТЬ 5: GRAB MODS (Mercury/Nil'e)
-- ==========================================
TabTgt:CreateSection("Grab Mods")
TabTgt:CreateToggle({
    Name = "Massless Grab", CurrentValue = false, Flag = "massT",
    Callback = function(on)
        if not on then return end
        WS.ChildAdded:Connect(function(c)
            if c.Name == "GrabParts" then
                task.wait(0.05)
                local d = c:FindFirstChild("DragPart")
                local ap = d and d:FindFirstChild("AlignPosition")
                if ap then
                    pcall(function()
                        ap.ForceLimitMode = Enum.ForceLimitMode.PerAxis
                        ap.MaxAxesForce = Vector3.new(math.huge, math.huge, math.huge)
                        ap.Responsiveness = 200; ap.MaxForce = math.huge
                    end)
                end
            end
        end)
    end,
})

TabTgt:CreateToggle({
    Name = "Kill Grab", CurrentValue = false, Flag = "killGrabT",
    Callback = function(on)
        if not on then return end
        WS.ChildAdded:Connect(function(c)
            if c.Name ~= "GrabParts" then return end
            task.wait(0.1)
            local gp = c:FindFirstChild("GrabPart")
            local wc = gp and gp:FindFirstChild("WeldConstraint")
            local p1 = wc and wc.Part1
            local model = p1 and p1.Parent
            if not model then return end
            local plr = P:GetPlayerFromCharacter(model)
            if not plr or plr == LP then return end
            local t = model:FindFirstChild("HumanoidRootPart")
            local th = model:FindFirstChildOfClass("Humanoid")
            if not t or not th or th.Health <= 0 then return end
            local f = WS.FallenPartsDestroyHeight
            task.spawn(function()
                sno(t); t.CFrame = CFrame.new(0, -50000, 0); zer(t)
                task.wait(0.1); WS.FallenPartsDestroyHeight = -45000
                task.wait(0.2); WS.FallenPartsDestroyHeight = f
            end)
            pcall(function() c:Destroy() end)
        end)
    end,
})

-- ==========================================
-- ЧАСТЬ 6: BLOBMAN LOOP (Nil'e)
-- ==========================================
TabBlob:CreateSection("Blobman Loop")
local Blob = { on = false, method = "Kick" }
local function getBlob()
    local h = hum(); local s = h and h.SeatPart
    if s and s.Parent and s.Parent.Name == "CreatureBlobman" then return s.Parent end
    local i = inv(); return i and i:FindFirstChild("CreatureBlobman")
end
local function blobBS(b)
    if not b then return end
    local sc = b:FindFirstChild("BlobmanSeatAndOwnerScript"); if not sc then return end
    local g = sc:FindFirstChild("CreatureGrab")
    local r = sc:FindFirstChild("CreatureRelease") or sc:FindFirstChild("CreatureDrop")
    local rd = b:FindFirstChild("RightDetector"); local ld = b:FindFirstChild("LeftDetector")
    if not (g and r and rd and ld) then return end
    return { g=g, r=r, rd=rd, ld=ld, rw=rd:FindFirstChild("RightWeld"), lw=ld:FindFirstChild("LeftWeld"), hrp=b:FindFirstChild("HumanoidRootPart"), seat=b:FindFirstChild("VehicleSeat") }
end
TabBlob:CreateDropdown({
    Name = "Blob Method", Options = { "Kick", "Lock", "Void", "Kill" },
    CurrentOption = "Kick", MultipleOptions = false, Flag = "blobM",
    Callback = function(v) Blob.method = getStr(v) or "Kick" end,
})
TabBlob:CreateToggle({
    Name = "Blobman Loop", CurrentValue = false, Flag = "blobT",
    Callback = function(on)
        Blob.on = on
        if not on then return end
        task.spawn(function()
            while Blob.on do
                RS.Heartbeat:Wait()
                local h = hum(); local me = hrp()
                if not h or not me then task.wait(0.1)
                else
                    local blob = getBlob()
                    if not blob then
                        if LP:FindFirstChild("CanSpawnToy") and LP.CanSpawnToy.Value then
                            pcall(function() SP:InvokeServer("CreatureBlobman", me.CFrame * CFrame.new(0, 15, 20), Vector3.zero) end)
                        end
                        task.wait(0.5)
                    else
                        local bs = blobBS(blob)
                        if bs and bs.seat and h.SeatPart ~= bs.seat then
                            me.CFrame = bs.seat.CFrame * CFrame.new(0, 2, 0); zer(me)
                            task.wait(0.05)
                            pcall(function() bs.seat:Sit(h) end)
                            task.wait(0.3)
                        elseif bs then
                            local t = thrp(S.target); local th = thum(S.target)
                            if t and th and th.Health > 0 and bs.hrp then
                                if (bs.hrp.Position - t.Position).Magnitude > 25 then
                                    bs.hrp.CFrame = t.CFrame; zer(bs.hrp)
                                end
                                pcall(function() bs.g:FireServer(bs.rd, t, bs.rw) end)
                                if Blob.method == "Kick" then
                                    pcall(function() bs.r:FireServer(bs.rw) end)
                                    th.Sit = true; zer(t); task.wait(0.02); th.Sit = false
                                elseif Blob.method == "Void" then
                                    sno(t); t.AssemblyLinearVelocity = Vector3.new(0, -1e8, 0); kline(t)
                                elseif Blob.method == "Kill" then
                                    pcall(function() bs.r:FireServer(bs.rw, t) end)
                                    pcall(function() th:ChangeState(Enum.HumanoidStateType.Dead) end)
                                    task.wait(0.1)
                                    if th.Parent and th.Health > 0 then pcall(function() th.Health = 0 end) end
                                elseif Blob.method == "Lock" then
                                    if not t:FindFirstChild("BenchBlobLock") then
                                        local bp = Instance.new("BodyPosition", t)
                                        bp.Name = "BenchBlobLock"
                                        bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge); bp.D = 100
                                        bp.Position = bs.hrp.Position + Vector3.new(0, 10, 0)
                                    else
                                        t.BenchBlobLock.Position = bs.hrp.Position + Vector3.new(0, 10, 0)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end,
})

-- ==========================================
-- ЧАСТЬ 7: DEFENSE (Anti-Grab, Anti-Kick)
-- ==========================================
TabDef:CreateSection("Anti Grab")
local AG = { on = false, held = false, conns = {}, rayP = RaycastParams.new() }
AG.rayP.FilterType = Enum.RaycastFilterType.Exclude
local function agClear()
    for _, c in ipairs(AG.conns) do pcall(function() c:Disconnect() end) end
    AG.conns = {}
end
local function agSetup(c)
    if not c or not AG.on then return end
    local t = c:WaitForChild("HumanoidRootPart", 5); local h = c:WaitForChild("Humanoid", 5)
    if not t or not h then return end
    pcall(function() h.RequiresNeck = false end)
    AG.rayP.FilterDescendantsInstances = { c }
    for _, part in ipairs(c:GetChildren()) do
        if part:IsA("BasePart") then
            table.insert(AG.conns, part.ChildAdded:Connect(function(ch)
                if ch.Name ~= "PartOwner" or AG.held then return end
                AG.held = true
                task.spawn(function()
                    while AG.on and part.Parent and part:FindFirstChild("PartOwner") do
                        pcall(function() ST:FireServer(LP) end)
                        pcall(function() RR:FireServer(t, 0) end)
                        task.wait()
                    end
                    AG.held = false
                end)
                t.Anchored = true
                task.spawn(function()
                    while AG.on and AG.held and t.Parent do
                        local dt = task.wait()
                        local md = h.MoveDirection; local p = t.Position
                        local sp = math.max(h.WalkSpeed, 16)
                        if md.Magnitude > 0 then p = p + Vector3.new(md.X, 0, md.Z).Unit * sp * dt end
                        local gh = WS:Raycast(p + Vector3.new(0, 3, 0), Vector3.new(0, -10, 0), AG.rayP)
                        if gh then p = Vector3.new(p.X, gh.Position.Y + (h.HipHeight > 0 and h.HipHeight or 2) + 1, p.Z) end
                        t.AssemblyAngularVelocity = Vector3.zero
                        local cam = WS.CurrentCamera.CFrame
                        local flat = Vector3.new(cam.LookVector.X, 0, cam.LookVector.Z)
                        t.CFrame = flat.Magnitude > 0 and CFrame.new(p, p + flat) or CFrame.new(p)
                    end
                end)
                task.wait(0.1); t.Anchored = false
            end))
        end
    end
end
TabDef:CreateToggle({
    Name = "Anti Grab (raycast)", CurrentValue = false, Flag = "agT",
    Callback = function(on)
        AG.on = on; agClear()
        if on then
            if LP.Character then agSetup(LP.Character) end
            table.insert(AG.conns, LP.CharacterAdded:Connect(function(c)
                task.wait(0.1); if AG.on then agSetup(c) end
            end))
        end
    end,
})

TabDef:CreateSection("Anti Kick")
local AKCfg = {
    Default = { name = "NinjaShuriken", off = CFrame.new(0,0,0) * CFrame.Angles(0, math.pi/2, math.pi/2), target = "Fire" },
    Pickaxe = { name = "ToolPickaxe", off = CFrame.new(-0.25, 0.45, 0.78) * CFrame.Angles(-math.pi/2, -math.pi/4, 0), target = "Torso" },
}
local AK = { on = false, mode = "Default" }
TabDef:CreateDropdown({
    Name = "Anti Kick Item", Options = { "Default", "Pickaxe" },
    CurrentOption = "Default", MultipleOptions = false, Flag = "akM",
    Callback = function(v) AK.mode = getStr(v) or "Default" end,
})
TabDef:CreateToggle({
    Name = "Anti Kick", CurrentValue = false, Flag = "akT",
    Callback = function(on)
        AK.on = on
        if not on then
            local i = inv()
            if i then for _, c in ipairs(i:GetChildren()) do
                if c.Name == "AntiKick" or c.Name == "NinjaShuriken" or c.Name == "ToolPickaxe" then
                    pcall(function() DT:FireServer(c) end)
                end
            end end
            return
        end
        task.spawn(function()
            while AK.on do
                RS.Heartbeat:Wait()
                local t = hrp(); local h = hum(); local i = inv()
                if not t or not h or h.Health <= 0 or not i then
                    task.wait(0.1)
                else
                    local cfg = AKCfg[AK.mode]
                    local toy
                    for _, c in ipairs(i:GetChildren()) do
                        if c.Name == cfg.name or c.Name == "AntiKick" then toy = c; break end
                    end
                    if not toy then
                        if LP:FindFirstChild("CanSpawnToy") and LP.CanSpawnToy.Value then
                            pcall(function() SP:InvokeServer(cfg.name, t.CFrame * CFrame.new(0, 12, 20), Vector3.zero) end)
                        end
                        task.wait(0.1)
                    else
                        toy.Name = "AntiKick"
                        for _, d in ipairs(toy:GetChildren()) do
                            if d:IsA("BasePart") then
                                d.CanTouch = false; d.CanCollide = false; d.CanQuery = false
                                d.Transparency = (AK.mode == "Default" and (d.Name == "Pyramid" or d.Name == "Main")) and 0 or 1
                            end
                        end
                        local st = toy:FindFirstChild("StickyPart")
                        local sn = toy:FindFirstChild("SoundPart")
                        if st and sn then
                            if not owned(sn) then sno(sn) end
                            local tgt
                            if cfg.target == "Fire" then tgt = t:FindFirstChild("FirePlayerPart") or t
                            else tgt = (h.Parent:FindFirstChild("UpperTorso") or h.Parent:FindFirstChild("Torso")) or t end
                            if tgt then pcall(function() SE:FireServer(st, tgt, cfg.off) end) end
                        end
                        task.wait(0.05)
                    end
                end
            end
        end)
    end,
})

-- ==========================================
-- ЧАСТЬ 8: VISUAL (PCLD)
-- ==========================================
TabVis:CreateSection("PCLD ESP")
local PCLD = { on = false, boxes = {}, fill = Color3.new(0,0,0), out = Color3.new(1,1,1) }
local function pldAdd(p)
    if not p:IsA("BasePart") or PCLD.boxes[p] then return end
    local c = chr(); if c and p:IsDescendantOf(c) then return end
    local proxy = Instance.new("Part")
    proxy.Name = "BenchPCLD"; proxy.Transparency = 1; proxy.Anchored = true
    proxy.CanCollide = false; proxy.CanQuery = false; proxy.CanTouch = false
    proxy.Size = Vector3.new(2.5, 7, p.Size.Z + 0.1); proxy.CFrame = p.CFrame
    proxy.Parent = WS.CurrentCamera
    local f = Instance.new("BoxHandleAdornment", CG)
    f.Adornee = proxy; f.AlwaysOnTop = true; f.ZIndex = 4; f.Size = proxy.Size
    f.Color3 = PCLD.fill; f.Transparency = 0.75
    local o = Instance.new("SelectionBox", CG)
    o.Adornee = proxy; o.LineThickness = 0.07; o.Color3 = PCLD.out
    local c1 = RS.RenderStepped:Connect(function(dt)
        if p.Parent and proxy.Parent then
            local k = math.clamp(dt * 12, 0, 1)
            proxy.CFrame = proxy.CFrame:Lerp(p.CFrame, k)
            proxy.Size = proxy.Size:Lerp(Vector3.new(2.5, 7, p.Size.Z + 0.1), k)
            f.Size = proxy.Size
        end
    end)
    PCLD.boxes[p] = { f=f, o=o, proxy=proxy, c1=c1 }
    p.AncestryChanged:Connect(function(_, par)
        if not par and PCLD.boxes[p] then
            local d = PCLD.boxes[p]
            pcall(function() d.c1:Disconnect() end)
            pcall(function() d.f:Destroy() end)
            pcall(function() d.o:Destroy() end)
            pcall(function() d.proxy:Destroy() end)
            PCLD.boxes[p] = nil
        end
    end)
end
TabVis:CreateToggle({
    Name = "PCLD ESP", CurrentValue = false, Flag = "pldT",
    Callback = function(on)
        PCLD.on = on
        if on then
            for _, d in ipairs(WS:GetDescendants()) do
                local n = d.Name:lower()
                if n == "playercharacterlocationdetector" or n == "partesp" then pldAdd(d) end
            end
            WS.DescendantAdded:Connect(function(d)
                if PCLD.on and d:IsA("BasePart") then
                    local n = d.Name:lower()
                    if n == "playercharacterlocationdetector" or n == "partesp" then pldAdd(d) end
                end
            end)
        else
            for p, d in pairs(PCLD.boxes) do
                pcall(function() d.c1:Disconnect() end)
                pcall(function() d.f:Destroy() end)
                pcall(function() d.o:Destroy() end)
                pcall(function() d.proxy:Destroy() end)
            end
            PCLD.boxes = {}
        end
    end,
})

-- ==========================================
-- ЧАСТЬ 9-16: UTILS (Packet, Break, Control, etc.)
-- ==========================================
TabSrv:CreateSection("Packet Lag")
local Packet = { on = false, mb = 1, delay = 0.5, str = string.rep("bench", 1000) }
TabSrv:CreateSlider({
    Name = "Size (MB)", Range = { 1, 9 }, Increment = 0.5, Suffix = "MB",
    CurrentValue = 1, Flag = "pkMB",
    Callback = function(v) Packet.mb = v end,
})
TabSrv:CreateToggle({
    Name = "Packet Lag", CurrentValue = false, Flag = "pkT",
    Callback = function(on)
        Packet.on = on
        if on then
            task.spawn(function()
                while Packet.on do
                    local by = math.floor(Packet.mb * 1048576)
                    local s = string.rep(Packet.str, math.floor(by / #Packet.str))
                    pcall(function() EL:FireServer(s) end)
                    task.wait(Packet.delay)
                end
            end)
        end
    end,
})

TabSrv:CreateSection("Breakers")
local function barrierBreak()
    local t0 = tick(); local broken = false
    while tick() - t0 < 10 and not broken do
        pcall(function() SP:InvokeServer("BallSnowball", CFrame.new(263.5, -4.5, 486.9), Vector3.zero) end)
        task.wait(0.5)
        for _, ch in ipairs(WS:GetChildren()) do
            if ch.Name == "Part" and ch:IsA("BasePart") and (ch.Position - Vector3.new(263.4, -4.79, 466.8)).Magnitude <= 2 then
                broken = true
                for _, plot in ipairs(WS.Plots:GetChildren()) do
                    local b = plot:FindFirstChild("Barrier")
                    if b then for _, bp in ipairs(b:GetChildren()) do if bp:IsA("BasePart") then bp.CanCollide = false end end end
                end
                break
            end
        end
    end
    return broken
end
TabSrv:CreateButton({
    Name = "Break Barrier",
    Callback = function()
        task.spawn(function()
            local ok = barrierBreak()
            notify("bench", ok and "barrier broken" or "failed", 3)
        end)
    end,
})

TabMisc:CreateSection("Control Player")
local Ctrl = { on = false, creature = nil, bv = nil, rayP = RaycastParams.new() }
Ctrl.rayP.FilterType = Enum.RaycastFilterType.Exclude
local function ctrlStop()
    Ctrl.on = false
    if Ctrl.creature then
        local ch = Ctrl.creature:FindFirstChildOfClass("Humanoid")
        if ch then ch.WalkSpeed = 16; ch.PlatformStand = false end
        Ctrl.creature = nil
    end
    if Ctrl.bv then Ctrl.bv:Destroy(); Ctrl.bv = nil end
    local h = hum(); if h then WS.CurrentCamera.CameraSubject = h end
end
local ctrlToggle = TabMisc:CreateToggle({
    Name = "Control Player", CurrentValue = false, Flag = "ctrlT",
    Callback = function(on)
        if not on then ctrlStop(); return end
        local me = chr(); local mh = hrp()
        if not me or not mh then return end
        local head = me:FindFirstChild("Head"); if not head then return end
        Ctrl.rayP.FilterDescendantsInstances = { me }
        local hit = WS:Raycast(head.Position, WS.CurrentCamera.CFrame.LookVector * 100, Ctrl.rayP)
        if not hit then return end
        local tgt = hit.Instance
        while tgt and not tgt:FindFirstChildOfClass("Humanoid") do tgt = tgt.Parent end
        if not tgt then return end
        local th = tgt.Humanoid; local t = tgt:FindFirstChild("HumanoidRootPart")
        if not th or not t or th.Health <= 0 then return end
        sno(t); line(t)
        th.WalkSpeed = 0
        Ctrl.creature = tgt; Ctrl.on = true
        local bv = Instance.new("BodyVelocity", mh)
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge); bv.Velocity = Vector3.zero
        Ctrl.bv = bv
        WS.CurrentCamera.CameraSubject = th
        local conn = RS.Heartbeat:Connect(function()
            if not Ctrl.on or not th.Parent or not hum() then conn:Disconnect(); return end
            bv.Velocity = hum().MoveDirection * 20
            t.CFrame = mh.CFrame + Vector3.new(0, -3, 0)
        end)
    end,
})
TabMisc:CreateKeybind({
    Name = "Control Bind", CurrentKeybind = "V", HoldToInteract = false, Flag = "ctrlB",
    Callback = function()
        local next = not Ctrl.on
        pcall(function() ctrlToggle:Set(next) end)
    end,
})

TabMisc:CreateSection("Util")
TabMisc:CreateButton({ Name = "Rejoin", Callback = function() TS:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end })
TabMisc:CreateButton({ Name = "Unload", Callback = function() pcall(function() Rayfield:Destroy() end) end })

notify("bench", "loaded", 3)