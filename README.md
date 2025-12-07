# ServerHitbox
a hitbox library fully made from scratch<br>
**[api explanation](https://github.com/hafpcuh/ServerHitbox?tab=readme-ov-file#hitbox-api)**, and **[hitbox config explanation](https://github.com/hafpcuh/ServerHitbox?tab=readme-ov-file#hitbox-config-explanation)**

### this library includes:
- hitbox shapes (block, and sphere)
- named hitboxes (optional)
- debug parts (thanks to ObjectCache)
- [cast rules](https://github.com/hafpcuh/ServerHitbox?tab=readme-ov-file#what-are-cast-rules)

## installation

### method 1: manually
* download the [latest release](https://github.com/hafpcuh/ServerHitbox/releases)
* insert the `.rbxm` file into **Roblox Studio**, and place it anywhere you like (e.g. ReplicatedStorage)

### method 2: filesystem
* download the `src` folder, or clone the repository (use `git clone`)
* place the `src` folder anywhere you like, and rename it to `ServerHitbox`, or anything else
* use [Rojo](https://github.com/rojo-rbx/rojo) to sync the files

## example usage
```lua
local ServerHitbox = -- // path to library

local Hitbox = ServerHitbox.new({
    CFrame = CFrame.new(0, 8, 0),
    Size = 7
})

Hitbox.Hit:Connect(function(
    Hit: Humanoid
)
    Hit:TakeDamage(25)
end)

Hitbox:Start()
```

## what are cast rules?
**cast rules are functions, that get used upon casting, and checking if they didnt break that rule**<br>
here are some examples of what they can do:
```lua
--[[
    hey, i want to make it, so it only hits parts named "HumanoidRootPart",
    for "accurate" hitboxes
]]

Hitbox:AddCastRule("Instance", function(Hit)
    return Hit.Name == "HumanoidRootPart"
end)
```

```lua
--[[
    hey, i want to make it, so it only can only hit humanoids,
    when their health is over 0

    (because really, whats the point of damaging the humanoid when its already dead)
]]

Hitbox:AddCastRule("Humanoid", function(Hit)
    return Hit.Health > 0
end)
```

## hitbox api
* ServerHitbox.new(Config: Config) | returns Hitbox
    - creates a new hitbox class

* ServerHitbox:GetActive(Key: string) | returns Hitbox?
    - returns the following hitbox (if it even exists in the first place)

* Hitbox:Start()
    - starts the hitbox, if not active
* Hitbox:Stop()
    - ends the hitbox, if active
* Hitbox:Cast() | returns { (Instance | Humanoid)? }
    - casts a bounding area
* Hitbox:Once()
    - creates a single hitbox, and fires .Hit if hit someone/something

* Hitbox:Attach(Instance: Instance?)
    - can either attach following Instance, or detach

* Hitbox:AddCastRule(For: "Humanoid" | "Instance", Rule: (Hit: Humanoid | Instance) -> ())
    - creates a new cast rule
* Hitbox:RemoveCastRule(For: "Humanoid" | "Instance", Index: number)
    - removes the following cast rule
* Hitbox:CheckCastRule(For: "Humanoid" | "Instance") | returns boolean
    - checks for that following rule, and returns a boolean

* Hitbox:GetCFrame() | returns CFrame
    - returns a cframe for hitbox placement

* Hitbox:Destroy()
    - self explanatory

## hitbox config explanation

### main variables (must add)
- CFrame **(CFrame)** |  self explanatory
- Size **(Vector3, or number)** | self explanatory

### optional variables
- Key **(string)** | hitbox name

- Parameters **(OverlapParams)** | self explanatory
- Rate **(number)** | how often should it cast a hitbox <sub>*(e.g. 1 = 1 per second, 3 = 3 per second, etc.)*<sub/>
    * **default is 60**
    * if rate is set under 0, it will run on every heartbeat frame

- Shape **("Block", or "Sphere")** | self explanatory (hitbox shape)
    * **default is "Block"**
- DetectionMethod **("Constant", or "Once")** | what detection method should it use
    * **default is "Once"**
    * Constant | doesn't stop at all
    * Once | once hit, it will stop
- HitMethod **("Humanoid", or "Instance")** | what hit method should it use
    * **default is "Humanoid"**
    * Humanoid | checks for humanoid
    * Instance | checks for literally any instance (part, truss, etc.)

- DestroyOnStop **(boolean)** | destroy itself on stopping?
    * **default is false**