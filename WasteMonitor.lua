_display = "46F52A304CF0A1E868F457BC10272802"  -- ID of the Large Screen
_screenWidth = 70                              -- Adjustable width of Large Screen
_screenHeight = 33                

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

_containerCount = 0
_machineNFUCount = 0
_machinePLPCount = 0

-- Limits
_maxWaste = 20
_maxNFU = 20
_maxPLP = 20
_maxEPC = 20

function sortingFunction(machine1, machine2)
    return machine1.Nick < machine2.Nick
end

function round(num, numDecimalPlaces, numPlaces)
    return string.format("%" .. (numPlaces or 0) .. "." .. (numDecimalPlaces or 0) .. "f", num)
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
function DrawBackground()
    gpu:setBackground(1, 0.2, 0.02, 0.5)
    gpu:setForeground(1, 1, 1, 1)
    w, h = gpu:getSize()
    gpu:fill(0, 0 + _screenOffset, w, 1, " ")
    gpu:flush()

    gpu:setText(3, 0 + _screenOffset, "Uranium Waste Recycling Plant")
    gpu:flush()
end



-- Get containers
containerIDs = component.proxy(component.findComponent(_containers))
containers = {}
for i, container in ipairs(containerIDs) do
    table.insert(containers,container)
    _containerCount = _containerCount + 1
end

-- Get NFU machines --
machineNFUIDs = component.proxy(component.findComponent(_nonFissleUranium))
machinesNFU = {}
for i, machine in ipairs(machineNFUIDs) do
    table.insert(machinesNFU, machine)
    _machineNFUCount = _machineNFUCount + 1
end
table.sort(machinesNFU, sortingFunction)

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
end

-- Get Plutonium Pellets machines --
machinePLPIDs = component.proxy(component.findComponent(_plutoniumPellet))
machinesPLP = {}
for i, machine in ipairs(machinePLPIDs) do
    table.insert(machinesPLP, machine)
end
table.sort(machinesPLP, sortingFunction)

-- Get Encased Plutonium Cells machines --
machineEPCIDs = component.proxy(component.findComponent(_encasedPlutoniumCell))
machinesEPC = {}
for i, machine in ipairs(machineEPCIDs) do
    table.insert(machinesEPC, machine)
end
table.sort(machinesPLP, sortingFunction)


-- Get Containers
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
end

-- Screen Offset to center content
_machineCount = 3
_screenOffset = 3
-- Fetch Large Display --
gpu = computer.getPCIDevices(classes.GPU_T1_C)[1]
screen = component.proxy(_display)
gpu:bindScreen(screen)

ClearScreen()
DrawBackground()

while true do

    gpu:setBackground(0, 0, 0, 1)
    gpu:setForeground(1, 1, 1, 1)

    gpu:setText(3, 2 + _screenOffset, "Process | Backlog | Status ")

    wasteAmount = getContainerAmount(wasteContainer)
    nfuAmount = getContainerAmount(nfuContainer)
    plpAmount = getContainerAmount(plpContainer)

    print("Uranium Waste: " .. wasteAmount)
    print("Non-fissle Uranium: " .. nfuAmount)
    print("Plutonium Pellets: " .. plpAmount)

    -- Set NFU
    if wasteAmount > _maxWaste then
        nfuProductionBoost = 2
    else
        nfuProductionBoost = 1
    end

    for i,machine in ipairs(machinesNFU) do
        if machine.productionBoost ~= nfuProductionBoost and machine.maxProductionBoost >= nfuProductionBoost then
            print("Setting potential for " .. machine.Nick .. " to " .. math.floor(nfuProductionBoost * 100) .. "%")
            machine:setProductionBoost(nfuProductionBoost)
        end
    end


    -- Set Plutonium Pellets
    if nfuAmount > _maxNFU then
        plpPotential = 1.5
    else
        plpPotential = 1
    end

    for i,machine in ipairs(machinesPLP) do
        if machine.potential ~= plpPotential and machine.maxPotential >= plpPotential then
            print("Setting potential for " .. machine.Nick .. " to " .. math.floor(plpPotential * 100) .. "%")
            machine:setPotential(plpPotential)
        end
    end

        -- Set Encased Plutonium Cells
        if plpAmount > _maxPLP then
            epcPotential = 1.5
        else
            epcPotential = 1
        end
    
        for i,machine in ipairs(machinesEPC) do
            if machine.potential ~= epcPotential and machine.maxPotential >= epcPotential then
                print("Setting potential for " .. machine.Nick .. " to " .. math.floor(epcPotential * 100) .. "%")
                machine:setPotential(epcPotential)
            end
        end

    event.pull(5)
end


-- if waste over threshold then sloop nfu
-- if waste under threshold and nfu over threshold then standby nfu