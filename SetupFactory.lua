local function SetupMachine(machineGroup,machineRecipe,machineClock,setStandby) 
    local comps = {}
    for _, i in pairs (component.proxy(component.findComponent(machineGroup))) do    
        table.insert(comps, i)
    end

    if machineRecipe ~= "" then
        for _, n in pairs (comps) do

            for _, r in pairs(n:getRecipes()) do
                if r.name == Recipe then
                    print(r.name)
                    n:getOutputInv():flush()
                    n:getInputInv():flush()
                    n:setRecipe(r)                
                    print ("Set to: ".. machineRecipe)
                else
                    --print ("Recipe on Machine not found")
                end
            end
        end
    end

    if machineClock ~= "" then
        for _, j in pairs (comps) do
            j:setPotential(machineClock/100)
            print ("Set Overclock on to: " .. tostring(machineClock) .. "%")
        end
    end

    if setStandby ~= "" then
        for _, m in pairs (comps) do
            m.standby = setStandby                
            print ("Set Standby to: " .. tostring(setStandby))
        end
    end
    print ("Factory Setup succesful")
end


Clock = 90
Recipe = "Alternate: Oil-Based Diamonds"
Standby = false
group = "I_DIA" 
SetupMachine(group,Recipe,Clock,Standby)

Clock = 100
Recipe = "Time Crystal"
Standby = false
group = "I_TIC" 
SetupMachine(group,Recipe,Clock,Standby)

Clock = 50
Recipe = "Excited Photonic Matter"
Standby = false
group = "I_EPM" 
SetupMachine(group,Recipe,Clock,Standby)

Clock = 81.942
Recipe = "Alternate: Synthetic Power Shard"
Standby = false
group = "I_POS" 
SetupMachine(group,Recipe,Clock,Standby)

Clock = 65.3717
Recipe = "Alternate: Dark Matter Trap"
Standby = false
group = "I_DMC" 
SetupMachine(group,Recipe,Clock,Standby)




