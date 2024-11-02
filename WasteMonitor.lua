-- Variables
_display = "7A9BCB6F4AF64114F5E2F99271C10643"  -- ID of the Large Screen
_screenWidth = 70                              -- Adjustable width of Large Screen
_screenHeight = 33                

_maxCounter = 60

-- Factory Variables
_factory = "F_PFR"
_level = "L_00"
_containers = "B_STC"

-- Item Variables
_uraniumWaste = "I_URW"
_nonFissleUranium = "I_NFU"
_plutoniumPellet = "I_PLP"
_encasedPlutoniumCell = "I_EPC"
_plutoniumFuelRod = "I_PFR"

wasteAmount = 0
nfuAmount = 0
plpAmount = 0
epcAmount = 0

wasteTrend = "stable    "
nfuTrend = "stable    "
plpTrend = "stable    "
epcTrend = "stable    "

_containerCount = 0
_machineNFUCount = 0
_machinePLPCount = 0

-- Limits
_maxWaste = 200
_maxNFU = 500
_maxPLP = 200
_maxEPC = 200


-- Functions

function round(num, numDecimalPlaces, numPlaces)
    return string.format("%" .. (numPlaces or 0) .. "." .. (numDecimalPlaces or 0) .. "f", num)
end


local function addEntry(inTable, inEntry)
    -- Add the new entry to the table

    table.insert(inTable, inEntry)
    
    -- Keep only the most recent 5 entries
    if #inTable > 5 then
        table.remove(inTable, 1)  -- Remove the oldest entry
    end
end

local function getTrend(values)
    local trends = {}
    local rate = 0
    local total = 0
    local count = 0

    for i = 1, #values do
        total = total + values[i] 
        count = count + 1
    end

    local averageValue = total / count

    for i = 2, #values do
        --trends[i-1] = values[i] - values[i-1]
        trends[i-1] = averageValue - values[i-1]
        rate = round(trends[i-1],0)
    end
    
    local trendType = "calculating"
    for _, change in ipairs(trends) do
        if change > 2 then
            trendType = "increasing "
        elseif change < -2 then
            trendType = "decreasing "
        else             
            trendType = "stable     "
        end
        
    end    

    trendData = {}
    trendData[1] = trendType
    trendData[2] = rate
    return trendData
end

local function padNumber(input,pad) 
    return string.format("% ".. pad .. "d", input)
end

--local function lpad(str, len, char)
--    str = tostring(str)
--    if char == nil then char = " " end
--    return str .. string.rep(char, len - #str)
--end


-- pad the left side
local lpad =
	function (s, l, c)
        s = tostring(s)
		local res = string.rep(c or ' ', l - #s) .. s
		return res
	end

function sortingFunction(machine1, machine2)
    return machine1.Nick < machine2.Nick
end


function getContainerAmount(container)
    containerAmount = 0
    containerInv = container:getInventories()
    for i,inventory in ipairs(containerInv) do
        if inventory.internalName == "StorageInventory" then
            containerAmount = inventory.ItemCount
        end
    end
    return containerAmount
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
function DrawBackground(title)
    gpu:setBackground(1, 0.2, 0.02, 0.5)
    gpu:setForeground(1, 1, 1, 1)
    w, h = gpu:getSize()
    gpu:fill(0, 0 + _screenOffset, w, 1, " ")
    gpu:flush()

    gpu:setText(3, 0 + _screenOffset, title)
    gpu:flush()
end


-- Get containers
containerIDs = component.proxy(component.findComponent(_containers))
containers = {}
for i, container in ipairs(containerIDs) do
    table.insert(containers,container)
    _containerCount = _containerCount + 1
end

for i, container in ipairs(containers) do
    containerNick = container.Nick
    if string.find(containerNick, _uraniumWaste) then
        wasteContainer = container
    end
    if string.find(containerNick, _nonFissleUranium) then
        nfuContainer = container
    end
    if string.find(containerNick, _plutoniumPellet) then
        plpContainer = container
    end
    if string.find(containerNick, _encasedPlutoniumCell) then
        epcContainer = container        
    end
    if string.find(containerNick, _plutoniumFuelRod) then
        pfrContainer = container        
    end
end


-- Get Machines
machineIDs = component.proxy(component.findComponent(_factory))
machines = {}
machinesNFU = {}
machinesPLP = {}
machinesEPC = {}
machinesPFR = {}

for i, machine in ipairs(machineIDs) do
    table.insert(machines,machine)
    --print(machine.Nick)
end

for i, machine in ipairs(machines) do
    machineNick = machine.Nick
    if string.find(machineNick, _nonFissleUranium) then
        table.insert(machinesNFU, machine)
    end
    if string.find(machineNick, _plutoniumPellet) then
        table.insert(machinesPLP, machine)
    end
    if string.find(machineNick, _encasedPlutoniumCell) then
        table.insert(machinesEPC, machine)
    end
    if string.find(machineNick, _encasedPlutoniumCell) then
        table.insert(machinesEPC, machine)
    end
    if string.find(machineNick, _plutoniumFuelRod) then
        table.insert(machinesPFR, machine)
    end
end

-- Screen Offset to center content
_machineCount = 3
_screenOffset = 3
-- Fetch Large Display --
gpu = computer.getPCIDevices(classes.GPU_T1_C)[1]
screen = component.proxy(_display)
gpu:bindScreen(screen)

ClearScreen()
DrawBackground("Uranium Waste Recycling Centre")

wasteAmounts = {}
nfuAmounts = {}
plpAmounts = {}
epcAmounts = {}

dataCounter = 0
nfuCounter = 0
plpCounter = 0
epcCounter = 0

wasteRate = 0
nfuRate = 0
plpRate = 0
epcRate = 0

while true do

    gpu:setBackground(0, 0, 0, 1)
    gpu:setForeground(1, 1, 1, 1)

    dataCounter = dataCounter + 1
    nfuCounter = nfuCounter + 1
    plpCounter = plpCounter + 1
    epcCounter = epcCounter + 1

    wasteAmount = getContainerAmount(wasteContainer)
    nfuAmount = getContainerAmount(nfuContainer)
    plpAmount = getContainerAmount(plpContainer)
    epcAmount = getContainerAmount(epcContainer)

    if dataCounter == _maxCounter then
        addEntry(wasteAmounts,wasteAmount)
        wasteData = getTrend(wasteAmounts)
        wasteTrend = wasteData[1]
        wasteRate = wasteData[2]

        addEntry(nfuAmounts,nfuAmount)
        nfuData = getTrend(nfuAmounts)
        nfuTrend = nfuData[1]
        nfuRate = nfuData[2]
       -- nfuTrend = getTrend(nfuAmounts)[1]

        addEntry(plpAmounts,plpAmount)
        plpData = getTrend(plpAmounts)
        plpTrend = plpData[1]
        plpRate = plpData[2]
        --plpTrend = getTrend(plpAmounts)[1]

        addEntry(epcAmounts,epcAmount)
        epcData = getTrend(epcAmounts)
        epcTrend = epcData[1]
        epcRate = epcData[2]
        --epcTrend = getTrend(epcAmounts)[1]

        dataCounter = 0
    end

    -- Set NFU
    if wasteAmount > _maxWaste then
        nfuProductionBoost = 2
        nfuStatus = "Slooped"
    else
        nfuProductionBoost = 1
        nfuStatus = "Normal "
    end

    for i,machine in ipairs(machinesNFU) do
        if machine.productionBoost ~= nfuProductionBoost and machine.maxProductionBoost >= nfuProductionBoost then
            --print("Setting potential for " .. machine.Nick .. " to " .. math.floor(nfuProductionBoost * 100) .. "%")
            machine:setProductionBoost(nfuProductionBoost)
        end
    end

    

    -- Set Plutonium Pellets
    if nfuAmount > _maxNFU then
        plpPotential = 1.5
        plpStatus = "Overclocked"
    else
        plpPotential = 1
        plpStatus = "Normal     "
    end

    for i,machine in ipairs(machinesPLP) do
        if machine.potential ~= plpPotential and machine.maxPotential >= plpPotential then
            --print("Setting potential for " .. machine.Nick .. " to " .. math.floor(plpPotential * 100) .. "%")
            machine:setPotential(plpPotential)
        end
    end

    

    -- Set Encased Plutonium Cells
    if plpAmount > _maxPLP then
        epcPotential = 1.5
        epcStatus = "Overclocked"
    else
        epcPotential = 1
        epcStatus = "Normal     "
    end

    for i,machine in ipairs(machinesEPC) do
        if machine.potential ~= epcPotential and machine.maxPotential >= epcPotential then
            --print("Setting potential for " .. machine.Nick .. " to " .. math.floor(epcPotential * 100) .. "%")
            machine:setPotential(epcPotential)
        end
    end



    -- Set Plutonium Fuel ROds
    if epcAmount > _maxEPC then
        pfrPotential = 1.5
        pfrStatus = "Overclocked"
    else
        pfrPotential = 1
        pfrStatus = "Normal     "
    end

    for i,machine in ipairs(machinesPFR) do
        if machine.potential ~= pfrPotential and machine.maxPotential >= pfrPotential then
            --print("Setting potential for " .. machine.Nick .. " to " .. math.floor(pfrPotential * 100) .. "%")
            machine:setPotential(pfrPotential)
        end
    end

    gpu:setText(3, 2 + _screenOffset, "Uranium Waste           : " .. lpad(wasteAmount,6," ") .. " - " .. wasteTrend .. " " .. lpad(wasteRate,5," ") .. "/min")
    gpu:setText(3, 3 + _screenOffset, "Non-Fissle Uranium      : " .. lpad(nfuAmount,6," ") .. " - " .. nfuTrend .. " " .. lpad(nfuRate,5," ") .. "/min")
    gpu:setText(3, 4 + _screenOffset, "Plutonium Pellets       : " .. lpad(plpAmount,6," ") .. " - " .. plpTrend .. " " .. lpad(plpRate,5," ") .. "/min")
    gpu:setText(3, 5 + _screenOffset, "Encased Plutonium Cells : " .. lpad(epcAmount,6," ") .. " - " .. epcTrend .. " " .. lpad(epcRate,5," ") .. "/min")

    gpu:setText(3, 9 + _screenOffset, "Non-Fissle Uranium      : " .. nfuStatus)
    gpu:setText(3, 10 + _screenOffset, "Plutonium Pellets       : " .. plpStatus)
    gpu:setText(3, 11 + _screenOffset, "Encased Plutonium Cells : " .. epcStatus)
    gpu:setText(3, 12 + _screenOffset, "Plutonium Fuel Rods     : " .. pfrStatus)

    gpu:flush()
    event.pull(1)
end


-- if waste over threshold then sloop nfu
-- if waste under threshold and nfu over threshold then standby nfu