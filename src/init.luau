--!strict

--[[
    "ServerHitbox" written by @Haf_p
    -------------------------------

    github: https://github.com/hafpcuh/ServerHitbox
    documentation is on github
]]

local ServerHitbox = {}
ServerHitbox.__index = ServerHitbox
ServerHitbox.__active = {} :: { [string]: self? }

ServerHitbox.__config = require(script.Config)
local HitboxConfig = ServerHitbox.__config

local RunService = game:GetService("RunService")

local Utilities = require(script.Utilities)

local Vendor = script.Vendor
local Signal = require(Vendor.SignalPlus)
local Maid = require(Vendor.Maid)
local ObjectCache = require(Vendor.ObjectCache)

-- // ⌄⌄⌄ this is for type checking, ignore this!!
local ConfigCheck = {
    CFrame = "CFrame",
    Size = { "Vector3", "number" },

    Key = "string",

    Parameters = "OverlapParams",
    Rate = "number",

    Shape = { "Block", "Sphere" },
    DetectionMethod = { "Constant", "Once" },
    HitMethod = { "Humanoid", "Instance" },

    DestroyOnStop = "boolean"
}

-- // debug variables (dont mind this, thanks)
local DefaultParameters = OverlapParams.new()
DefaultParameters.FilterType = Enum.RaycastFilterType.Exclude
DefaultParameters.FilterDescendantsInstances = {workspace.Terrain :: any}

local DebugTemplate = Instance.new("Part")
DebugTemplate.Name = "SERVERHITBOX_DEBUG"
DebugTemplate.Anchored = true
DebugTemplate.CanCollide = false
DebugTemplate.CanTouch = false
DebugTemplate.CanQuery = false

local DebugCacheFolder = Instance.new("Folder")
DebugCacheFolder.Name = "SERVERHITBOX_DEBUG_CACHE"
DebugCacheFolder.Parent = workspace.Terrain

local DebugChacheAmount = 2 ^ 9
local DebugCache = ObjectCache.new(DebugTemplate, DebugChacheAmount, DebugCacheFolder) :: any

-- // types
type self = typeof(setmetatable(
    {} :: {
        -- // main
        Maid: Maid.Maid,
        Key: string?,

        CastRules: CastRules,
        CastHit: { Hit? },
        AlreadyHit: { Hit? },
        
        Active: boolean,
        AttachedTo: Instance?,

        Hit: Signal.Signal<Instance>,

        -- // config
        CFrame: CFrame,
        Size: Vector3,

        Parameters: OverlapParams,
        Rate: number,

        Shape: Shape,
        DetectionMethod: DetectionMethods,
        HitMethod: HitMethods,

        DestroyOnStop: boolean
    }, {} :: typeof(ServerHitbox))
)

type CastRule = (Hit: Instance | Humanoid) -> boolean
type CastRules = { [HitMethods]: { CastRule? } }
type Hit = (Instance | Humanoid)

type Shape = "Block" | "Sphere"
type DetectionMethods = "Constant" | "Once"
type HitMethods = "Humanoid" | "Instance"

type Config = {
    -- // MUST add
    CFrame: CFrame,
    Size: Vector3 | number,

    -- // optional
    Key: string?,

    Parameters: OverlapParams?,
    Rate: number?,

    Shape: Shape?,
    DetectionMethod: DetectionMethods?,
    HitMethod: HitMethods?,

    DestroyOnStop: boolean?
}

-- // local methods
local function CreateDebugPart(
    self: self,
    Hit: boolean
)
    if not HitboxConfig.DebugEnabled then return end

    local Size = self.Size
    local Shape = self.Shape

    local DebugPart = DebugCache:GetPart(self:GetCFrame())
    local Thread = Maid.new()

    DebugPart.Size = Shape == "Block"
        and Size
        or Vector3.one * Size.Magnitude
    DebugPart.CastShadow = false
    DebugPart.Shape = Shape == "Block"
        and Enum.PartType.Block
        or Enum.PartType.Ball

    DebugPart.Material = HitboxConfig.DebugProperties.Material
    DebugPart.Transparency = HitboxConfig.DebugProperties.Transparency
    DebugPart.Color = Hit
        and HitboxConfig.DebugProperties.HitColor
        or HitboxConfig.DebugProperties.BaseColor

    Thread:GiveTask(task.delay(HitboxConfig.DebugProperties.LifeTime, function()
        DebugPart.Parent = DebugCache.CacheHolder
        DebugCache:ReturnPart(DebugPart)

        Thread:Destroy()
    end))

    DebugPart.Parent = DebugCacheFolder
end

-- // shared methods
function ServerHitbox.new(
    Config: Config
): self?
    -- // checking
    Utilities.assert((Config :: any).CFrame ~= nil, "No CFrame provided.")
    Utilities.assert(Config.Size ~= nil, "No size provided.")

    for Name, Value in Config do
        local Expected = ConfigCheck[Name]
        Utilities.TypeCheck(Value, Expected)
    end

    -- // constructing
    local self: self = setmetatable({
        Maid = Maid.new(),
        Key = Config.Key,

        CastRules = {Humanoid = {}, Instance = {}} :: any,
        CastHit = {},
        AlreadyHit = {},

        Active = false,
        AttachedTo = nil,

        Hit = Signal() :: any,

        CFrame = Config.CFrame,
        Size = (typeof(Config.Size) == "number"
            and Vector3.one * Config.Size
            or Config.Size) :: Vector3,

        Parameters = Config.Parameters or DefaultParameters,
        Rate = Config.Rate or 60,

        Shape = Config.Shape or "Block",
        DetectionMethod = Config.DetectionMethod or "Once",
        HitMethod = Config.HitMethod or "Humanoid",

        DestroyOnStop = Config.DestroyOnStop or false
    }, ServerHitbox)

    self.Maid:GiveTask(self.Hit)

    if self.Key then
        ServerHitbox.__active[self.Key] = self
    end

    return self
end

function ServerHitbox.Start(
    self: self
)
    if self.Active then return end
    self.Active = true

    local Rate = self.Rate
   
    table.clear(self.CastHit)
    table.clear(self.AlreadyHit)

    self.Maid.ACTIVE_HITBOX = Rate <= 0
        and RunService.Heartbeat:Connect(function()
            self:Once()
        end)
        or Utilities.Frequency(function()
            self:Once()
        end, Rate)
end

function ServerHitbox.Stop(
    self: self
)
    if not self.Active then return end
    self.Active = false

    self.Maid.ACTIVE_HITBOX = nil

    if self.DestroyOnStop then
        self:Destroy()
    end
end

function ServerHitbox.Cast(
    self: self
): { Hit? }
    local CastHit = self.CastHit

    local Parameters = self.Parameters
    local Shape = self.Shape
    local DetectionMethod = self.DetectionMethod
    local HitMethod = self.HitMethod

    local CFrame = self:GetCFrame()
    local Size = self.Size

    local Hit = {}
    local Cast = Shape == "Block"
        and workspace:GetPartBoundsInBox(CFrame, Size, Parameters)
        or workspace:GetPartBoundsInRadius(CFrame.Position, Size.Magnitude / 2, Parameters)

    for _, Instance in Cast :: any do
        if not table.find(CastHit, Instance) then
            table.insert(CastHit, Instance)
        else
            if DetectionMethod == "Once" then continue end
        end

        local InstanceRuleCheck = self:CheckCastRule("Instance", Instance)
        if not InstanceRuleCheck then continue end

        if HitMethod == "Humanoid" then
            local Model = Instance:FindFirstAncestorOfClass("Model")
            if not Model then continue end

            local Humanoid = Model:FindFirstChildOfClass("Humanoid")
            if not Humanoid then continue end

            local HumanoidRuleCheck = self:CheckCastRule("Humanoid", Humanoid)
            if not HumanoidRuleCheck then continue end

            table.insert(Hit, Humanoid)
        else
            table.insert(Hit, Instance)
        end
    end

    return Hit :: any
end

function ServerHitbox.Once(
    self: self
)
    local DetectionMethod = self.DetectionMethod

    local CastResults = self:Cast()
    CreateDebugPart(self, CastResults[1] ~= nil)
    if not CastResults[1] then return end

    local LocalHit = {}

    for _, Hit in CastResults do
        if
            not Hit
            or table.find(LocalHit, Hit)
        then continue end

        if DetectionMethod == "Once" then
            if table.find(self.AlreadyHit, Hit) then continue end
        end

        table.insert(LocalHit, Hit)
        table.insert(self.AlreadyHit, Hit)
        self.Hit:Fire(Hit)
    end

    if DetectionMethod == "Once" then
        self:Stop()
    end
end

function ServerHitbox.Attach(
    self: self,
    Instance: Instance?
)
    local Parameters = self.Parameters

    -- // no instance
    if not Instance then
        if not self.AttachedTo then return end

        local FilterIndex = table.find(Parameters.FilterDescendantsInstances, self.AttachedTo)
        if FilterIndex then
            table.remove(Parameters.FilterDescendantsInstances, FilterIndex)
        end

        self.AttachedTo = nil
        return
    end

    -- // provided instance
    Utilities.TypeCheck(Instance, "Instance")
    if Instance:IsA("Model") then
        Utilities.assert(Instance.PrimaryPart ~= nil, "Model has no PrimaryPart.")
    end

    table.insert(Parameters.FilterDescendantsInstances, Instance)
    self.AttachedTo = Instance:IsA("Model")
        and Instance.PrimaryPart
        or Instance
end

function ServerHitbox.AddCastRule(
    self: self,

    For: HitMethods,
    Rule: CastRule
)
    local CastRules = self.CastRules
    local FollowingRules = CastRules[For]
    Utilities.assert(FollowingRules ~= nil)

    table.insert(FollowingRules, Rule)
end

function ServerHitbox.RemoveCastRule(
    self: self,

    For: HitMethods,
    Index: number
)
    local FollowingRules = self.CastRules[For]
    Utilities.assert(FollowingRules ~= nil)

    table.remove(FollowingRules, Index)
end

function ServerHitbox.CheckCastRule(
    self: self,

    For: HitMethods,
    Hit: Hit
)
    local FollowingRules = self.CastRules[For]
    if
        not FollowingRules
        or #FollowingRules == 0
    then return true end

    for _, Rule in FollowingRules do
        if not Rule then continue end
        
        if not Rule(Hit) then return false end
    end

    return true
end

function ServerHitbox.GetCFrame(
    self: self
): CFrame
    local AttachedCFrame = self.AttachedTo
        and (self.AttachedTo :: any).CFrame
        or CFrame.identity

    return AttachedCFrame * self.CFrame
end

function ServerHitbox.Destroy(
    self: self
)
    if self.Key then
        ServerHitbox.__active[self.Key] = nil
    end

    self:Stop()

    self.Maid:DoCleaning()
    setmetatable(self :: any, nil)
end

function ServerHitbox:GetActive(
    Key: string
)
    return ServerHitbox.__active[Key]
end

return ServerHitbox