---@diagnostic disable: param-type-mismatch, undefined-global, lowercase-global
-- Configurable Variables --
                  -- Output of Recipe used in Machine
_building = "F_ECR"  
_floor = "L_01"                         -- Name of building encompassing multiple manufacturings
_machineType = "I_STP"                   -- Nickname/Groups of machines (This name needs to be equal to the name of the machines)
--_display = "D97856474FE177531459D686C925D757"  -- ID of the Large Screen
_screenWidth = 40                              -- Adjustable width of Large Screen
_screenHeight = 40                             -- Adjustable height of Large Screen

-- Variables --
_machineCount = 0
_screenOffset = 0
_lastRate = {}
_lastState = {}
_stateCounter = {}
_stateFrequency = 5
_stateOffCounter = {}

-- Internet Variables --
card = computer.getPCIDevices(classes.FINInternetCard)[1]
_influxDBWriteCounter = 0

function sortingFunction(machine1, machine2)
  return machine1.Nick < machine2.Nick
end


-- Fetch machines --
_display = component.proxy(component.findComponent("Display " .. _machineType))

machineIDs = component.proxy(component.findComponent(_machineType))

machines = {}

for i, machine in ipairs(machineIDs) do
	machineCheck = machine.canChangePotential
    if machineCheck == true then
    	table.insert(machines, machine)
    	_machineCount = _machineCount + 1
    end
   
end

print(_machineCount)

table.sort(machines, sortingFunction)

-- Screen Offset to center content
_screenOffset = math.floor((_screenHeight - _machineCount - 9) / 2)

-- Fetch Large Display --
gpu = computer.getPCIDevices(classes.GPU_T1_C)[1]
screen = component.proxy(component.findComponent("Display " .. _machineType))[1]
gpu:bindScreen(screen)

print(gpu:getSize())

-- Utilities --
function round(num, numDecimalPlaces, numPlaces)
    return string.format("%" .. (numPlaces or 0) .. "." .. (numDecimalPlaces or 0) .. "f", num)
end

function BoolToState(standby)
    if standby then
        return "Off"
    else
        return " On"
    end
end

-- Display Manipulation (Main Loop) --
function PrintData()
    -- Header settings --
    totalPowerConsumption = 0
    maxPowerConsumption = 0
    totalIngredients = 0
    totalProductivity = 0
    totalProducts = 0
    totalOutput = 0
    totalOutputExpected = 0

    gpu:setBackground(0, 0, 0, 1)
    gpu:setForeground(1, 1, 1, 1)
    recipe = machines[1]:getRecipe()
    recipeName = recipe.name
    ingredients = recipe:getIngredients()
    products = recipe:getProducts()
    ingredientsNeeded = {}
    for r, ingredient in pairs(ingredients) do
        ingredientsNeeded[r] = (60 / machines[1].cycleTime) * ingredients[r].amount
    end

    productsProduced = {}
    for p, product in pairs(products) do
        productsProduced[p] = ((60 / machines[1].cycleTime) * products[p].amount) / machines[1].potential
    end
 

    --ingredientsNeeded = (60 / machines[1].cycleTime) * ingredients[1].amount
    --productsProduced = (60 / machines[1].cycleTime) * products[1].amount

	gpu:setBackground(1, 0.2, 0.02, 0.5)
    gpu:setForeground(1, 1, 1, 1)
    
	gpu:setText(3, 0 + _screenOffset, recipeName .. " Production")
	
    gpu:setBackground(0, 0, 0, 1)
    gpu:setForeground(1, 1, 1, 1)

    --gpu:setText(3, 1 + _screenOffset, "Output: " .. productsProduced[1] .. " / min")
    gpu:setText(3, 2 + _screenOffset, "ID | Rate   | State ")
    



    -- Production Data --
    for i, machine in ipairs(machines) do
    	machineID = machine.Nick
        machineID = machineID:gsub(_building,"")
        machineID = machineID:gsub(_floor,"")
        machineID = machineID:gsub(_machineType,"")
        machineID = machineID:gsub(" ","")

        machineInputInv = machine:getInputInv()

        invItems = {}
        for j = 0, machineInputInv.size do
            local stack = machineInputInv:getStack(j)
            if stack ~= nil and stack.item ~= nil and stack.item.type ~= nil then                        
                minItems = stack.item.type.max / 2
                actualItems = stack.count
                --print(stack.item.type.name .. " - " ..actualItems .. " / " .. minItems)
                if actualItems < minItems then
                    --print(stack.item.type.name)
                end
            end
        end
                
        machineFactoryConnectors= machine:getFactoryConnectors()      

        for j, connector in ipairs(machineFactoryConnectors) do
            --print(connector.blocked)
        end

        machinePotential = machine.potential

        machineProductivity = round(machine.productivity * 100, 1, 5)
        machineOutput = round(((machineProductivity / 100) * productsProduced[1]) * machinePotential, 1, 4)
        machineOutputExpected = round(( productsProduced[1]) * machinePotential, 1)
        
        print(productsProduced[1])

        -- Instantiate variables --
        if not _lastRate[i] then
            _lastRate[i] = 0.0
            _lastState[i] = false
            _stateCounter[i] = 0
            _stateOffCounter[i] = 0
        end

        -- Checking and settings state of machines --
        _stateCounter[i] = _stateCounter[i] + 1

        if _stateCounter[i] >= _stateFrequency then
            _stateCounter[i] = 0

            if math.floor(progress) ~= math.floor(_lastRate[i]) then
                _lastState[i] = false
                
                
                invItems = {}
                for j = 0, machineInputInv.size do
                    local stack = machineInputInv:getStack(j)
                    if stack ~= nil and stack.item ~= nil and stack.item.type ~= nil then
                        
                        minItems = stack.item.type.max / 2
                        actualItems = stack.count
                        if actualItems < minItems then
                            --print(stack.item.type.name)
                        end
                        --for m, v in pairs(invItems) do
                        --    print(m .. " - " .. v)
                        --end
                    end
                end
                _stateOffCounter[i] = 0

            else
                _stateOffCounter[i] = _stateOffCounter[i] + 1
                if _stateOffCounter[i] >= 5 then
                    _lastState[i] = true
                end
            end
        end

        _lastRate[i] = progress

        standby = machine.standby
        if standby then
            _lastState[i] = standby
        end

        if _lastState[i] then
            powerConsumption = 0
        end

        -- Calculating totals of all machines --
        totalIngredients = totalIngredients + (machineProductivity / 100) * ingredientsNeeded[1]
        totalProductivity = totalProductivity + machineProductivity
        totalProducts = totalProducts + machineOutput
        totalRate = round((totalProductivity / _machineCount), 1)
        totalOutput = totalOutput + machineOutput
        totalOutputExpected = totalOutputExpected + machineOutputExpected

        gpu:flush()
        gpu:setText(3, i + 3 + _screenOffset, (machineID .. " | " .. machineProductivity .. "% | " .. BoolToState(_lastState[i])))
    end


    --gpu:setText(3, _machineCount + 6 + _screenOffset, "Total Input: " .. round(totalIngredients, 1) .. " / " .. round(totalInput,1))
    gpu:setText(3, _machineCount + 5 + _screenOffset, "Total Output: " .. round(totalProducts, 1) .. " / " .. round(totalOutputExpected,1))
    gpu:setText(3, _machineCount + 6 + _screenOffset, "Total Rate:   " .. round(totalRate, 1) .. "%")

    gpu:setBackground(1, 0.2, 0.02, 0.5)
    gpu:setForeground(1, 1, 1, 1)
    w, h = gpu:getSize()
    gpu:fill(0, _machineCount + 8 + _screenOffset, w, 1, " ")
    --gpu:setText(3, _machineCount + 8 + _screenOffset, "Total Power Consumption: " .. totalPowerConsumption .. "MW" .. " / " .. maxPowerConsumption .. "MW")
    gpu:flush()
    sleep(1)
end

-- Clears the screen before writing information --
function ClearScreen()
    gpu:setBackground(0, 0, 0, 1)
    gpu:setForeground(0, 0, 0, 1)
    gpu:setSize(_screenWidth, _screenHeight)
    w, h = gpu:getSize()
    gpu:fill(0, 0, w, h, " ")
    gpu:flush()
end


-- Draws background and title
function DrawBackground()
    gpu:setBackground(1, 0.2, 0.02, 0.5)
    gpu:setForeground(1, 1, 1, 1)
    w, h = gpu:getSize()
    gpu:fill(0, 0 + _screenOffset, w, 1, " ")
    gpu:flush()

    --gpu:setText(3, 0 + _screenOffset, _output .. " Production")
    gpu:flush()
end

-- Main Loop --
ClearScreen()
DrawBackground()
while true do
    PrintData()
end