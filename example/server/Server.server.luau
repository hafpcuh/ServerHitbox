local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Libraries = ReplicatedStorage.Libraries
local ServerHitbox = require(Libraries.ServerHitbox)

local TestHitbox = workspace.TestHitbox

local Hitbox = ServerHitbox.new({
    CFrame = CFrame.new(0, 8, 0),
    Size = 7
})

Hitbox:Attach(TestHitbox)

Hitbox:AddCastRule("Instance", function(
    Hit: BasePart
)
    return Hit.Name == "HumanoidRootPart"
end)

Hitbox:AddCastRule("Humanoid", function(
    Hit: Humanoid
)
    return Hit.Health > 0
end)

Hitbox.Hit:Connect(function(
    Humanoid: Humanoid
)
    print("hit", Humanoid)
    Humanoid:TakeDamage(15)

    task.wait(1)
    Hitbox:Start()
end)

Hitbox:Start()