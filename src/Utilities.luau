--!strict

local Utilities = {}

local RunService = game:GetService("RunService")

function Utilities.Format(
    Table: { string }
)
    return table.concat(Table, ", ", 1, #Table - 1) .. ", or " .. Table[#Table]
end

--[[
    the default assert function has problems, so instead, im making a "custom" one
    refer to this: devforum.roblox.com/t/be-careful-when-using-assert-and-why
]]
function Utilities.assert(
    Condition: boolean,

    Message: string?,
    Warn: boolean?
)
    if not Condition then
        if
            Warn == nil
            or not Warn
        then
            error(Message or "Something went wrong.", 2)
        else
            warn(Message or "No warn message.")
        end
    end
end

function Utilities.TypeCheck(
    Variable: any,
    ExpectedType: string | { string? }
)
    local Type = typeof(Variable)
    local Fails = 0

    local function Check(
        Expected: string
    )
        if Type ~= Expected then
            if Variable == Expected then return end
            Fails += 1
        end
    end
    
    if typeof(ExpectedType) == "string" then
        Check(ExpectedType)
    else
        for _, Expected in ExpectedType do
            if not Expected then continue end
            Check(Expected)
        end
    end

    if Fails == #ExpectedType then
        assert(typeof(Variable) == ExpectedType, `Invalid type, expected {Utilities.Format(ExpectedType)} ({Variable}, {Type}).`)
    end
end

function Utilities.Frequency(
    Callback: (number) -> (),
    Hertz: number
)
    local Last = time()
    Hertz = 1 / Hertz

    return RunService.Heartbeat:Connect(function(
        ServerDelta
    )
        local Delta = time() - Last
        if Delta < Hertz then return end

        Last = time()
        Callback(ServerDelta)
    end)
end

return Utilities