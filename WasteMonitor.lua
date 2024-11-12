    ---@diagnostic disable: param-type-mismatch, undefined-global, lowercase-global
    -- Variables
    local _display = "7A9BCB6F4AF64114F5E2F99271C10643"  -- ID of the Large Screen
    local _panel = component.proxy("C7FF93A3480547FA3B13CFAF2BB63076")
    local _screenWidth = 70                              -- Adjustable width of Large Screen
    local _screenHeight = 33         
    
    local RGBAColor

    local _maxCounter = 60

    -- Factory Variables
    local _factory = "F_PFR"
    local _level = "L_00"
    local _containers = "B_STC"

    -- Item Variables
    local _uraniumWaste = "I_URW"
    local _nonFissleUranium = "I_NFU"
    local _plutoniumPellet = "I_PLP"
    local _encasedPlutoniumCell = "I_EPC"
    local _plutoniumFuelRod = "I_PFR"

    local machineItems = {_uraniumWaste,_nonFissleUranium,_plutoniumPellet,_encasedPlutoniumCell,_plutoniumFuelRod}

    wasteAmount = 0
    nfuAmount = 0
    plpAmount = 0
    epcAmount = 0

    wasteTrend = "stable    "
    nfuTrend = "stable    "
    plpTrend = "stable    "
    epcTrend = "stable    "

    local _containerCount = 0
    _machineNFUCount = 0
    _machinePLPCount = 0

    -- Limits
    local _maxWaste = 200
    local _maxNFU = 500
    local _maxPLP = 200
    local _maxEPC = 200

    machineProductivity = {}


    -- Functions

    local function round(num, numDecimalPlaces, numPlaces)
        return string.format("%" .. (numPlaces or 0) .. "." .. (numDecimalPlaces or 0) .. "f", num)
    end


    function round2(x)
        return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
    end


    local function roundPotential(x)
        x = x * 100000
        y = x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
        y = y / 100000
        return y

    -- math.floor(a+0.5)potential * 100, 3) / 100
    end

    local function addEntry(inTable, inEntry)
        -- Add the new entry to the table
        table.insert(inTable, inEntry)    
        -- Keep only the most recent 5 entries
        if #inTable > 10 then
            table.remove(inTable, 1)  -- Remove the oldest entry
        end
    end

    function calculate_trend(data)
        if #data < 2 then
            return "Calculating"
        end
    
        local n = #data
        local sum_x = 0
        local sum_y = 0
        local sum_xy = 0
        local sum_x2 = 0
    
        for i = 1, n do
            local x = i  -- Using index as x value (1, 2, ..., 10)
            local y = data[i]
    
            sum_x = sum_x + x
            sum_y = sum_y + y
            sum_xy = sum_xy + (x * y)
            sum_x2 = sum_x2 + (x * x)
        end
    
        -- Calculate slope (m) and intercept (b)
        local slope = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x * sum_x)
        local intercept = (sum_y - slope * sum_x) / n

        print(intercept)

        trend = "Stable"

        if slope < 0 then
            trend =  "Going down "
        elseif slope > 0 then
            trend =  "Going up   "
        end
    
        return trend
        --return slope, intercept
    end
    
    
    --local data_points = {500, 626, 514, 512, 689, 748, 596, 546, 474, 550}
    --local slope, intercept = calculate_trend(data_points)
    
    print("Slope:", slope)
    print("Intercept:", intercept)

    local function getTrend(values)
        local trends = {}
        local rate = ""
        local total = 0
        local count = 0

        for i = 1, #values do
            total = total + values[i] 
            count = count + 1
        end

        local averageValue = total / count

        change = values[count] - values[1]
        rate = change / count
        
        local trendType = "calculating"

        if rate > 2 then
            trendType = "increasing "
        elseif rate < -2 then
            trendType = "decreasing "
        else             
            trendType = "stable     "
        end  

        trendData = {}
        trendData[1] = trendType
        trendData[2] = rate
        return trendData
    end

    local function padNumber(input,pad) 
        return string.format("% ".. pad .. "d", input)
    end

    local function sortingFunction(machine1, machine2)
        return machine1.Nick < machine2.Nick
    end
    
    -- pad the left side
    local lpad =
        function (s, l, c)
            s = tostring(s)
            local res = string.rep(c or ' ', l - #s) .. s
            return res
        end

    local function sortingFunction(machine1, machine2)
        return machine1.Nick < machine2.Nick
    end

    local function getContainerAmount(container)
        containerAmount = 0
        containerInv = container:getInventories()
        for i,inventory in ipairs(containerInv) do
            if inventory.internalName == "StorageInventory" then
                containerAmount = inventory.ItemCount
            end
        end
        return containerAmount
    end

    local function offOn(machine)
        machine.standby = true
        event.pull(1)
        machine.standby = false
    end

    local function setMachines(machineTable, machineCount, standardRate, increase, action)
        
        local newMachineCount = machineCount + increase
        local newPotential = (newMachineCount * (standardRate / 100) / machineCount)
        local productivity = 0

        for i,machine in ipairs(machineTable) do
            machineNick = machine.Nick
            currentPotential = roundPotential(machine.potential)

            productivity = productivity + roundPotential(machine.productivity) * 100

            if roundPotential(currentPotential) * 100 ~= roundPotential(newPotential) * 100  then

                print("Setting for " .. machineNick .. " is currently " .. roundPotential(currentPotential) * 100 .. "%. Changing to " .. roundPotential(newPotential) * 100 .. "%")
                machine:setPotential(newPotential)
                offOn(machine)
            end   
        end

        return productivity / machineCount

    end

    -- Clears the screen before writing information --
    local function ClearScreen()
        gpu:setBackground(0, 0, 0, 1)
        gpu:setForeground(0, 0, 0, 1)
        gpu:setSize(_screenWidth, _screenHeight)
        w, h = gpu:getSize()
        gpu:fill(0, 0, w, h, " ")
        gpu:flush()
    end


    -- Draws background and title
    local function DrawBackground(title)
        gpu:setBackground(1, 0.2, 0.02, 0.5)
        gpu:setForeground(1, 1, 1, 1)
        w, h = gpu:getSize()
        gpu:fill(0, 0 + _screenOffset, w, 1, " ")
        gpu:flush()

        gpu:setText(3, 0 + _screenOffset, title)
        gpu:flush()
    end

    local function rgba(r,g,b,a)
        ---@type RGBAColor
        local col = {}
        col.R = r
        col.G = g
        col.B = b
        col.A = a
        return col
    end

    function setModuleColor(module, color)
        module:setColor(color.R, color.G, color.B, color.A)
    end

    function setTextBackGroundColor(color)
        gpu:setBackground(color.R, color.G, color.B, color.A)
    end

    local colourOverClocked = rgba(1, 0.2, 0.02, 0.5)
    local colourSlooped = rgba(1, 0, 1, 0.5)
    local colourNormal = rgba(1, 0, 0, 0)
    local colourGood = rgba(0, 1, 0, 0.2)
    local colourBad = rgba(1, 0, 0, 0.2)

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
    allMachines = {}
    machines = {}
    machineCount = {}

    for i, machineItem in pairs(machineItems) do
        --machines[machineItem] = {}
    end

    machines[_nonFissleUranium] = {}
    machines[_plutoniumPellet] = {}
    machines[_encasedPlutoniumCell] = {}
    machines[_plutoniumFuelRod] = {}

    machineCount[_nonFissleUranium] = 0
    machineCount[_plutoniumPellet] = 0
    machineCount[_encasedPlutoniumCell] = 0
    machineCount[_plutoniumFuelRod] = 0

    for i, machine in ipairs(machineIDs) do
        table.insert(allMachines,machine)
        --print(machine.Nick)
    end

    table.sort(allMachines, sortingFunction)

    for i, machine in ipairs(allMachines) do
        machineNick = machine.Nick
        machineCheck = machine.canChangePotential
        if machineCheck == true then
            if string.find(machineNick, _nonFissleUranium) then
                table.insert(machines[_nonFissleUranium], machine)
                machineCount[_nonFissleUranium] = machineCount[_nonFissleUranium] + 1
            end
            if string.find(machineNick, _plutoniumPellet) then
                table.insert(machines[_plutoniumPellet], machine)
                machineCount[_plutoniumPellet] = machineCount[_plutoniumPellet] + 1
            end
            if string.find(machineNick, _encasedPlutoniumCell) then
                table.insert(machines[_encasedPlutoniumCell], machine)
                machineCount[_encasedPlutoniumCell] = machineCount[_encasedPlutoniumCell] + 1
            end
            if string.find(machineNick, _plutoniumFuelRod) then
                table.insert(machines[_plutoniumFuelRod], machine)
                machineCount[_plutoniumFuelRod] = machineCount[_plutoniumFuelRod] + 1
            end
        end
    end

    machineData = {}

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

            wasteTrend = calculate_trend(wasteAmounts)
            nfuTrend = calculate_trend(nfuAmounts)
            plpTrend = calculate_trend(plpAmounts)
            epcTrend = calculate_trend(epcAmounts)

            dataCounter = 0
        end



        nfuOverClockModule = _panel:getModule(5,7,0)
        nfuSloopedkModule = _panel:getModule(7,7,0)
        
        plpOverClockModule = _panel:getModule(5,5,0)
        plpSloopedkModule = _panel:getModule(7,5,0)

        epcOverClockModule = _panel:getModule(5,3,0)
        epcSloopedkModule = _panel:getModule(7,3,0)

        pfrOverClockModule = _panel:getModule(5,1,0)
        pfrSloopedkModule = _panel:getModule(7,1,0)

        setModuleColor(nfuOverClockModule, colourNormal)
        setModuleColor(nfuSloopedkModule, colourNormal)
        setModuleColor(plpOverClockModule, colourNormal)
        setModuleColor(plpSloopedkModule, colourNormal)
        setModuleColor(epcOverClockModule, colourNormal)
        setModuleColor(epcSloopedkModule, colourNormal)
        setModuleColor(pfrOverClockModule, colourNormal)
        setModuleColor(pfrSloopedkModule, colourNormal)



        -- Set NFU
        if wasteAmount > _maxWaste and nfuAmount < _maxNFU then
            nfuProductionBoost = 2
            nfuStatus = "Slooped    "
            setModuleColor(nfuSloopedkModule, colourSlooped)
            nfuBackground = colourSlooped
        else
            nfuProductionBoost = 1
            nfuStatus = "Normal     "
            setModuleColor(nfuSloopedkModule, colourNormal)
            nfuBackground = colourGood
        end


        nfuProductivity = 0

        for i,machine in ipairs(machines[_nonFissleUranium]) do
            nfuProductivity = nfuProductivity + roundPotential(machine.productivity) * 100

            if machine.productionBoost ~= nfuProductionBoost and machine.maxProductionBoost >= nfuProductionBoost then
                print("Setting potential for " .. machine.Nick .. " to " .. math.floor(nfuProductionBoost * 100) .. "%")
                machine:setProductionBoost(nfuProductionBoost)
            end
        end
        
        nfuProductivity = nfuProductivity / machineCount[_nonFissleUranium]

        if nfuProductivity < 100 then
            nfuBackground = colourBad
        end

        -- Set Plutonium Pellets
        if wasteAmount > _maxWaste then
            machineIncrease = 1
            plpStatus = "Overclocked"
            setModuleColor(plpOverClockModule, colourOverClocked)
            plpBackground = colourOverClocked
        else
            machineIncrease = 0
            plpStatus = "Normal     "
            setModuleColor(plpOverClockModule, colourNormal)
            plpBackground = colourGood
        end

        plpProductivity = setMachines(machines[_plutoniumPellet], machineCount[_plutoniumPellet], 96, machineIncrease, plpStatus)     

        if plpProductivity < 100 then
            machineIncrease = 0
            plpStatus = "Normal     "
            setModuleColor(plpOverClockModule, colourNormal)
            plpBackground = colourBad
        end

        -- Set Encased Plutonium Cells
        if plpAmount > _maxPLP then
            machineIncrease = 3
            epcStatus = "Overclocked"
            setModuleColor(epcOverClockModule, colourOverClocked)
            epcBackground = colourOverClocked
        else
            machineIncrease = 0
            epcStatus = "Normal     "
            setModuleColor(epcOverClockModule, colourNormal)
            epcBackground = colourBad
        end

        epcProductivity = setMachines(machines[_encasedPlutoniumCell], machineCount[_encasedPlutoniumCell], 96, machineIncrease, epcStatus)
        
        if epcProductivity < 100 then
            machineIncrease = 0
            epcStatus = "Normal     "
            setModuleColor(epcOverClockModule, colourNormal)
            epcBackground = colourBad
        end
    
        -- Set Plutonium Fuel ROds
        if epcAmount > _maxEPC then
            machineIncrease = 2
            pfrStatus = "Overclocked"
            setModuleColor(pfrOverClockModule, colourOverClocked)
            pfrBackground = colourOverClocked
        else
            machineIncrease = 0
            pfrStatus = "Normal     "
            setModuleColor(pfrOverClockModule, colourNormal)
            pfrBackground = colourBad

        end

        pfrProductivity = setMachines(machines[_plutoniumFuelRod], machineCount[_plutoniumFuelRod], 96, machineIncrease, pfrStatus)

        if pfrProductivity < 100 then
            machineIncrease = 0
            pfrStatus = "Normal     "
            setModuleColor(epcOverClockModule, colourNormal)
            pfrBackground = colourBad
        end
    


        gpu:setText(3, 2 + _screenOffset, "Uranium Waste           : " .. lpad(wasteAmount,6," ") .. " - " .. wasteTrend .. " " .. lpad(round(wasteRate,0),5," ") .. "/min")
        gpu:setText(3, 3 + _screenOffset, "Non-Fissle Uranium      : " .. lpad(nfuAmount,6," ") .. " - " .. nfuTrend .. " " .. lpad(round(nfuRate,0),5," ") .. "/min")
        gpu:setText(3, 4 + _screenOffset, "Plutonium Pellets       : " .. lpad(plpAmount,6," ") .. " - " .. plpTrend .. " " .. lpad(round(plpRate,0),5," ") .. "/min")
        gpu:setText(3, 5 + _screenOffset, "Encased Plutonium Cells : " .. lpad(epcAmount,6," ") .. " - " .. epcTrend .. " " .. lpad(round(epcRate,0),5," ") .. "/min")

        setTextBackGroundColor(nfuBackground)
        gpu:setText(3,  9 + _screenOffset, "Non-Fissle Uranium      : " .. nfuStatus .. "  " .. lpad(round(nfuProductivity,1) .. "%",6," "))

        setTextBackGroundColor(plpBackground)
        gpu:setText(3, 10 + _screenOffset, "Plutonium Pellets       : " .. plpStatus .. "  " .. lpad(round(plpProductivity,1) .. "%",6," "))

        setTextBackGroundColor(epcBackground)
        gpu:setText(3, 11 + _screenOffset, "Encased Plutonium Cells : " .. epcStatus .. "  " .. lpad(round(epcProductivity,1) .. "%",6," "))

        setTextBackGroundColor(pfrBackground)
        gpu:setText(3, 12 + _screenOffset, "Plutonium Fuel Rods     : " .. pfrStatus .. "  " .. lpad(round(pfrProductivity,1) .. "%",6," "))

        gpu:flush()
        event.pull(1)
    end


    -- if waste over threshold then sloop nfu
    -- if waste under threshold and nfu over threshold then standby nfu