-- bench.lua — one file, ready to paste
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
local P  = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local REP = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local TS = game:GetService("TeleportService")
local CG = game:GetService("CoreGui")
local LP = P.LocalPlayer

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

local W = Library:CreateWindow({ Title = "bench", Center = true, AutoShow = true, TabPadding = 8, MenuFadeTime = 0.2 })
local T = {
    Tgt  = W:AddTab("Target"),
    Blob = W:AddTab("Blobman"),
    Def  = W:AddTab("Defense"),
    Vis  = W:AddTab("Visual"),
    Srv  = W:AddTab("Server"),
    Misc = W:AddTab("Misc"),
}

local S = { target = nil }

local function chr() return LP.Character end
local function hrp() local c = chr(); return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = chr(); return c and c:FindFirstChildOfClass("Humanoid") end
local function thrp(p) local c = p and p.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function thum(p) local c = p and p.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function inv() return WS:FindFirstChild(LP.Name .. "SpawnedInToys") end
local function zer(b) if b then b.AssemblyLinearVelocity = Vector3.zero; b.AssemblyAngularVelocity = Vector3.zero end end
local function sno(b) if b then pcall(function() SNO:FireServer(b, b.CFrame) end) end end
local function line(b) if b then pcall(function() CL:FireServer(b, Vector3.zero, b.Position, false) end) end end
local function kline(b) if b then pcall(function() DL:FireServer(b) end) end end
local function owned(b) local o = b and b:FindFirstChild("PartOwner"); return o and o.Value == LP.Name end
local function vis(on)
    local c = chr(); if not c then return end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BasePart") then d.LocalTransparencyModifier = on and 0 or 1 end
    end
end
local function plist()
    local t = {}
    for _, p in ipairs(P:GetPlayers()) do if p ~= LP then table.insert(t, p.DisplayName .. " (" .. p.Name .. ")") end end
    table.sort(t); return t
end
local function pick(s)
    if not s or s == "" then return nil end
    return P:FindFirstChild(s:match("%((.-)%)") or s)
end

-- === Target list ===
local tgtBox = T.Tgt:AddLeftGroupbox("Target")
local targetDrop = tgtBox:AddDropdown("tgtPick", {
    Values = plist(), Default = nil, Multi = false,
    Callback = function(v) S.target = pick(v) end,
})
P.PlayerAdded:Connect(function() task.defer(function() targetDrop:Refresh(plist(), true) end) end)
P.PlayerRemoving:Connect(function(p)
    if S.target == p then S.target = nil end
    task.defer(function() targetDrop:Refresh(plist(), true) end)
end)

local methodBox = T.Tgt:AddRightGroupbox("Ghost Grab")
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
            local plr = S.target
            local t = thrp(plr); local th = thum(plr)
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

methodBox:AddToggle("ghostT", {
    Text = "Ghost Grab", Default = false,
    Callback = function(on)
        if on and S.target then ghostStart() else ghostStop() end
    end,
}):AddKeyPicker("ghostB", {
    Default = "F", Callback = function(st)
        if st and S.target then
            local g = methodBox:GetToggle("ghostT")
            g:Set(not g:Get())
        end
    end,
})

-- === Snowball ===
local Snow = { on = false }
methodBox:AddToggle("snowT", {
    Text = "Snowball Ragdoll", Default = false,
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
}):AddKeyPicker("snowB", {
    Default = "M", Callback = function(st)
        if st and S.target then
            local g = methodBox:GetToggle("snowT"); g:Set(not g:Get())
        end
    end,
})

-- === Loop Target ===
local Loop = { on = false, method = "Kick", height = 10, slots = {} }

local function loopClear(plr)
    local s = Loop.slots[plr]
    if not s then return end
    pcall(function() s.bp:Destroy() end)
    pcall(function() s.bg:Destroy() end)
    Loop.slots[plr] = nil
end
local function loopClearAll() for p in pairs(Loop.slots) do loopClear(p) end; Loop.slots = {} end

local function loopTick()
    local me = hrp(); if not me then return end
    for p in pairs(Loop.slots) do if not p.Parent or not thrp(p) then loopClear(p) end end
    local plr = S.target; if not plr then loopClearAll(); return end
    local t = thrp(plr); local th = thum(plr)
    if not t or not th or th.Health <= 0 then loopClear(plr); return end
    if (me.Position - t.Position).Magnitude > 20 then me.CFrame = t.CFrame * CFrame.new(0, -8, 0); zer(me) end
    sno(t); line(t)
    th.PlatformStand = true; zer(t)
    if Loop.method == "Kick" then
        sno(t); th.Sit = true; task.wait(); kline(t); task.wait(0.02); th.Sit = false
    elseif Loop.method == "Lock" then
        local s = Loop.slots[plr]
        if not s or s.bp.Parent ~= t then
            loopClear(plr)
            local bp = Instance.new("BodyPosition", t)
            bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge); bp.D = 100; bp.P = 50000
            local bg = Instance.new("BodyGyro", t)
            bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge); bg.D = 100; bg.P = 50000
            Loop.slots[plr] = { bp = bp, bg = bg }
            s = Loop.slots[plr]
        end
        s.bp.Position = me.Position + Vector3.new(0, Loop.height, 0)
        s.bg.CFrame = me.CFrame
    elseif Loop.method == "Kill" then
        sno(t); t.CFrame = CFrame.new(0, -50000, 0); zer(t)
    elseif Loop.method == "Void" then
        sno(t); t.AssemblyLinearVelocity = Vector3.new(0, -1e8, 0); kline(t)
    elseif Loop.method == "Heaven" then
        sno(t)
        if not t:FindFirstChild("BenchHeaven") then
            local bv = Instance.new("BodyVelocity", t)
            bv.Name = "BenchHeaven"
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Velocity = Vector3.new(0, 250, 0)
            task.delay(2, function() if bv then bv:Destroy() end end)
        end
    end
end

methodBox:AddDropdown("loopM", {
    Values = { "Kick", "Lock", "Kill", "Void", "Heaven" }, Default = "Kick",
    Callback = function(v) Loop.method = v end,
})
methodBox:AddSlider("loopH", {
    Text = "Lock Height", Min = 3, Max = 40, Default = 10,
    Callback = function(v) Loop.height = v end,
})
methodBox:AddToggle("loopT", {
    Text = "Loop Target", Default = false,
    Callback = function(on)
        Loop.on = on
        if on then
            if not S.target then Library:Notify({ Title = "bench", Description = "pick target", Time = 2 }); return end
            task.spawn(function()
                while Loop.on do pcall(loopTick); task.wait(0.03) end
                loopClearAll()
            end)
        else loopClearAll() end
    end,
}):AddKeyPicker("loopB", {
    Default = "F", Callback = function(st)
        if st then local g = methodBox:GetToggle("loopT"); g:Set(not g:Get()) end
    end,
})

-- === Grab Mods ===
local Grab = T.Tgt:AddRightGroupbox("Grab Mods")
local Anchor = { on = false, parts = {} }

Grab:AddToggle("massT", {
    Text = "Massless Grab", Default = false,
    Callback = function(on)
        if not on then return end
        WS.ChildAdded:Connect(function(c)
            if c.Name == "GrabParts" then
                task.wait(0.05)
                local d = c:FindFirstChild("DragPart")
                local ap = d and d:FindFirstChild("AlignPosition")
                local ao = d and d:FindFirstChild("AlignOrientation")
                if ap then
                    pcall(function()
                        ap.ForceLimitMode = Enum.ForceLimitMode.PerAxis
                        ap.MaxAxesForce = Vector3.new(math.huge, math.huge, math.huge)
                        ap.Responsiveness = 200; ap.MaxForce = math.huge
                    end)
                end
                if ao then pcall(function() ao.Responsiveness = 200; ao.MaxTorque = math.huge end) end
            end
        end)
    end,
})

Grab:AddToggle("killGrabT", {
    Text = "Kill Grab", Default = false,
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

Grab:AddToggle("anchorT", {
    Text = "Anchor Grab", Default = false,
    Callback = function(on)
        Anchor.on = on
        if on then
            WS.ChildAdded:Connect(function(c)
                if c.Name ~= "GrabParts" then return end
                task.wait(0.05)
                local gp = c:FindFirstChild("GrabPart")
                local wc = gp and gp:FindFirstChild("WeldConstraint")
                local p1 = wc and wc.Part1
                if not p1 or not p1.Parent then return end
                local main = p1.Parent:FindFirstChild("SoundPart") or p1.Parent:FindFirstChild("Main") or p1
                for _, ch in ipairs(main:GetChildren()) do
                    if ch:IsA("BodyPosition") or ch:IsA("BodyGyro") then ch:Destroy() end
                end
                local bp = Instance.new("BodyPosition", main)
                bp.Position = main.Position; bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge); bp.D = 100
                local bg = Instance.new("BodyGyro", main)
                bg.CFrame = main.CFrame; bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge); bg.D = 100
                Anchor.parts[p1.Parent] = { bp = bp, bg = bg }
            end)
        else
            for _, d in pairs(Anchor.parts) do pcall(function() d.bp:Destroy() end); pcall(function() d.bg:Destroy() end) end
            Anchor.parts = {}
        end
    end,
})

-- === Control Player ===
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

T.Misc:AddLeftGroupbox("Control"):AddToggle("ctrlT", {
    Text = "Control Player (V)", Default = false,
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
        local jc = UIS.JumpRequest:Connect(function()
            if Ctrl.on and th.Parent then th:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
        task.spawn(function()
            while Ctrl.on and th.Parent and th.Health > 0 do task.wait() end
            jc:Disconnect(); if conn.Connected then conn:Disconnect() end; ctrlStop()
        end)
    end,
}):AddKeyPicker("ctrlB", {
    Default = "V", Callback = function(st)
        if st then
            local g = T.Misc:GetGroupbox and T.Misc:GetGroupbox("Control")
            if g then local tg = g:GetToggle("ctrlT"); tg:Set(not tg:Get()) end
        end
    end,
})

-- === Anti-Grab ===
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

T.Def:AddLeftGroupbox("Anti Grab"):AddToggle("agT", {
    Text = "Anti Grab (raycast)", Default = false,
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

-- === Anti Snowball / Bomb / Paint ===
T.Def:AddLeftGroupbox("Anti Snow/Bomb/Paint")

local AS = { on = false, last = 0, conns = {} }
T.Def:GetGroupbox and nil
T.Def:AddLeftGroupbox("Anti Snow/Bomb/Paint"):AddToggle("asT", {
    Text = "Anti Snowball", Default = false,
    Callback = function(on)
        AS.on = on
        for _, c in ipairs(AS.conns) do pcall(function() c:Disconnect() end) end; AS.conns = {}
        if not on then return end
        local function setup(c)
            if not c then return end
            local t = c:WaitForChild("HumanoidRootPart", 5); local h = c:WaitForChild("Humanoid", 5)
            if not t or not h then return end
            for _, d in ipairs(c:GetDescendants()) do
                if d:IsA("BasePart") then
                    table.insert(AS.conns, d.Touched:Connect(function(hit)
                        if hit and (string.find(hit.Name:lower(), "snowball") or
                           string.find((hit.Parent and hit.Parent.Name or ""):lower(), "snowball")) then
                            AS.last = os.clock()
                        end
                    end))
                end
            end
            table.insert(AS.conns, RS.Heartbeat:Connect(function()
                if not t.Parent or not h.Parent then return end
                local r = h:FindFirstChild("Ragdolled")
                local rag = (r and r:IsA("BoolValue") and r.Value) or h:GetState() == Enum.HumanoidStateType.Physics
                if rag and os.clock() - AS.last < 2 then
                    local _, y = t.CFrame:ToOrientation()
                    t.AssemblyAngularVelocity = Vector3.zero
                    t.CFrame = CFrame.new(t.Position) * CFrame.Angles(0, y, 0)
                end
            end))
        end
        setup(LP.Character)
        table.insert(AS.conns, LP.CharacterAdded:Connect(function(c) task.wait(0.1); if AS.on then setup(c) end end))
    end,
})

T.Def:AddLeftGroupbox("Anti Snow/Bomb/Paint"):AddToggle("abT", {
    Text = "Anti Explode", Default = false,
    Callback = function(on)
        if on then
            task.spawn(function()
                local c = WS.ChildAdded:Connect(function(ch)
                    if ch.Name ~= "Part" or not ch:IsA("BasePart") then return end
                    local t = hrp(); local h = hum()
                    if not t or not h then return end
                    if (ch.Position - t.Position).Magnitude < 40 then
                        t.Anchored = true; task.wait(0.01); t.Anchored = false
                        zer(t); h:ChangeState(Enum.HumanoidStateType.Running)
                    end
                end)
                while on do task.wait() end
                c:Disconnect()
            end)
        end
    end,
})

T.Def:AddLeftGroupbox("Anti Snow/Bomb/Paint"):AddToggle("apT", {
    Text = "Anti Paint/Poison", Default = false,
    Callback = function(on)
        if on then
            WS.DescendantAdded:Connect(function(d)
                if d.Name == "PaintPlayerPart" or d.Name == "PainPlayerPart" then
                    task.defer(function() if d and d.Parent then d:Destroy() end end)
                end
            end)
            for _, d in ipairs(WS:GetDescendants()) do
                if d.Name == "PaintPlayerPart" or d.Name == "PainPlayerPart" then d:Destroy() end
            end
        end
    end,
})

-- === Anti-Kick ===
local AKCfg = {
    Default = { name = "NinjaShuriken", off = CFrame.new(0,0,0) * CFrame.Angles(0, math.pi/2, math.pi/2), target = "Fire" },
    Pickaxe = { name = "ToolPickaxe", off = CFrame.new(-0.25, 0.45, 0.78) * CFrame.Angles(-math.pi/2, -math.pi/4, 0), target = "Torso" },
    Kunai   = { name = "NinjaKunai", off = CFrame.new(0, -1.2, 0) * CFrame.Angles(0, math.pi/2, math.pi/2), target = "Fire" },
}
local AK = { on = false, mode = "Default" }

T.Def:AddRightGroupbox("Anti Kick")

T.Def:GetGroupbox and nil
T.Def:AddRightGroupbox("Anti Kick"):AddDropdown("akM", {
    Values = { "Default", "Pickaxe", "Kunai" }, Default = "Default",
    Callback = function(v) AK.mode = v end,
})
T.Def:AddRightGroupbox("Anti Kick"):AddToggle("akT", {
    Text = "Anti Kick", Default = false,
    Callback = function(on)
        AK.on = on
        if not on then
            local i = inv()
            if i then for _, c in ipairs(i:GetChildren()) do
                if c.Name == "AntiKick" or c.Name == "NinjaShuriken" or c.Name == "ToolPickaxe" or c.Name == "NinjaKunai" then
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

-- === Blobman ===
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

T.Blob:AddLeftGroupbox("Blob Loop")

T.Blob:GetGroupbox and nil
T.Blob:AddLeftGroupbox("Blob Loop"):AddDropdown("blM", {
    Values = { "Kick", "Lock", "Void", "Kill" }, Default = "Kick",
    Callback = function(v) Blob.method = v end,
})

T.Blob:AddLeftGroupbox("Blob Loop"):AddToggle("blT", {
    Text = "Blobman Loop", Default = false,
    Callback = function(on)
        Blob.on = on
        if not on then return end
        task.spawn(function()
            while Blob.on do
                RS.Heartbeat:Wait()
                local h = hum(); local me = hrp(); if not h or not me then task.wait(0.1) else
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
                            local plr = S.target; local t = thrp(plr); local th = thum(plr)
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

-- === Gucci Save ===
local G = { busy = false, pinkCF = CFrame.new(-491, -7, -166) }

local function slideTo(cf, part)
    if not part or not part.Parent then return end
    local st = part.CFrame
    for i = 1, 20 do
        if not part.Parent then return end
        part.CFrame = st:Lerp(cf, i / 20)
        zer(part); task.wait()
    end
    part.CFrame = cf
end

T.Def:AddRightGroupbox("Gucci Save")
T.Def:GetGroupbox and nil
T.Def:AddRightGroupbox("Gucci Save"):AddButton("gSave", {
    Text = "Gucci Save (slide + train)",
    Func = function()
        if G.busy then return end
        local me = hrp(); local h = hum(); if not me or not h then return end
        G.busy = true
        task.spawn(function()
            local save = me.CFrame
            slideTo(G.pinkCF, me)
            local map = WS:FindFirstChild("Map")
            local t = map and map:FindFirstChild("AlwaysHereTweenedObjects")
            t = t and t:FindFirstChild("Train"); t = t and t:FindFirstChild("Object")
            t = t and t:FindFirstChild("ObjectModel"); t = t and t:FindFirstChild("Seat")
            if t then
                pcall(function() t:Sit(h) end)
                local t0 = tick()
                while tick() - t0 < 3 do
                    pcall(function() RR:FireServer(me, 0) end); task.wait()
                end
                task.wait(0.2); pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end)
                task.wait(0.2); me.CFrame = save; zer(me)
            else me.CFrame = save end
            G.busy = false
        end)
    end,
})

-- === PCLD ESP ===
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

T.Vis:AddLeftGroupbox("PCLD")

T.Vis:GetGroupbox and nil
T.Vis:AddLeftGroupbox("PCLD"):AddToggle("pldT", {
    Text = "PCLD ESP", Default = false,
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

-- === Packet Lag ===
local Packet = { on = false, mb = 1, delay = 0.5, str = string.rep("bench", 1000) }

T.Srv:AddLeftGroupbox("Packet Lag")

T.Srv:GetGroupbox and nil
T.Srv:AddLeftGroupbox("Packet Lag"):AddSlider("pkMB", {
    Text = "Size (MB)", Min = 1, Max = 9, Default = 1, Rounding = 1,
    Callback = function(v) Packet.mb = v end,
})
T.Srv:AddLeftGroupbox("Packet Lag"):AddSlider("pkD", {
    Text = "Delay (s)", Min = 0.1, Max = 3, Default = 0.5, Rounding = 2,
    Callback = function(v) Packet.delay = v end,
})
T.Srv:AddLeftGroupbox("Packet Lag"):AddButton("pkOne", {
    Text = "Send One Packet",
    Func = function()
        local by = math.floor(Packet.mb * 1048576)
        local s = string.rep(Packet.str, math.floor(by / #Packet.str))
        pcall(function() EL:FireServer(s) end)
    end,
})
T.Srv:AddLeftGroupbox("Packet Lag"):AddToggle("pkT", {
    Text = "Packet Lag", Default = false,
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

-- === Breakers ===
T.Srv:AddRightGroupbox("Breakers")

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

T.Srv:AddRightGroupbox("Breakers"):AddButton("brkT", {
    Text = "Break Barrier",
    Func = function()
        task.spawn(function()
            local ok = barrierBreak()
            Library:Notify({ Title = "bench", Description = ok and "barrier broken" or "failed", Time = 3 })
        end)
    end,
})

-- === Anti Banana ===
local function abanRun()
    local me = hrp(); local h = hum(); local c = chr()
    if not me or not h or not c then return end
    local ll = c:FindFirstChild("Left Leg"); local rl = c:FindFirstChild("Right Leg")
    local t = c:FindFirstChild("Torso")
    if not ll or not rl or not t then return end
    local hp = h.Health; h.Health = h.MaxHealth
    local f = WS.FallenPartsDestroyHeight; local save = t.CFrame
    WS.FallenPartsDestroyHeight = -200000
    pcall(function() RR:FireServer(me, 2) end); task.wait(0.5)
    rl.CFrame = CFrame.new(0, -60000, 0); ll.CFrame = CFrame.new(0, -60000, 0)
    task.wait(0.3); t.CFrame = CFrame.new(0, -59970, 0)
    task.wait(0.5); t.CFrame = save; task.wait(0.5)
    WS.FallenPartsDestroyHeight = f; h.Health = hp
end

T.Def:AddRightGroupbox("Anti Banana")
T.Def:GetGroupbox and nil
T.Def:AddRightGroupbox("Anti Banana"):AddButton("abnB", {
    Text = "Delete Legs",
    Func = function() task.spawn(abanRun) end,
})
T.Def:AddRightGroupbox("Anti Banana"):AddToggle("abnT", {
    Text = "Auto Anti Banana", Default = false,
    Callback = function(on)
        if on then
            task.spawn(function()
                while on do
                    local c = chr(); local h = c and c:FindFirstChildOfClass("Humanoid")
                    if c and h and h.Health > 0 and c:FindFirstChild("Left Leg") and c:FindFirstChild("Right Leg") then
                        pcall(abanRun); task.wait(0.5)
                    else task.wait(0.2) end
                end
            end)
        end
    end,
})

-- === Water Walk ===
T.Misc:AddRightGroupbox("Water Walk")
T.Misc:GetGroupbox and nil
T.Misc:AddRightGroupbox("Water Walk"):AddToggle("wwT", {
    Text = "Water Walk", Default = false,
    Callback = function(on)
        local m = WS:FindFirstChild("Map")
        local a = m and m:FindFirstChild("AlwaysHereTweenedObjects")
        local o = a and a:FindFirstChild("Ocean")
        local ob = o and o:FindFirstChild("Object")
        local om = ob and ob:FindFirstChild("ObjectModel")
        if om then for _, ch in ipairs(om:GetChildren()) do if ch:IsA("BasePart") then ch.CanCollide = on end end end
    end,
})

-- === Util ===
T.Misc:AddRightGroupbox("Util")
T.Misc:GetGroupbox and nil
T.Misc:AddRightGroupbox("Util"):AddButton("rejoinB", {
    Text = "Rejoin",
    Func = function() TS:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end,
})
T.Misc:AddRightGroupbox("Util"):AddButton("unloadB", {
    Text = "Unload",
    Func = function() pcall(function() Library:Unload() end) end,
})

Library:Notify({ Title = "bench", Description = "loaded", Time = 3 })