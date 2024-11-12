function isFluid(item_type_name)
    --checks to see if an inventory item is a fluid
    local fluids = {"Water","Crude Oil","Heavy Oil Residue","Fuel","Turbofuel","Liquid Biofuel","Alumina Solution","Sulfuric Acid","Nitrogen Gas","Nitric Acid"}
    isafluid = false
    for _,f in pairs(fluids) do
      if item_type_name == f then
        isafluid = true
        break
      end
    end
    return isafluid
  end
   
  function AggregateSlots(slots, outputslots)
    --[[
        This function takes the table structure of InventoryMachine where multiple slots may contain 
        the same item and aggregates all similar items into a single invetory entry.  For example,
        an industrial container with 48 slots filled with the same item.
        Known bug: Design only accounts for filled or partially filled slots in % fill of overall container. 
        This would be a nonsense number if the container had a mix of parts since slot max may be different
        for each item.
    ]]
    local stackmax = slots[1].max
    local sum = {}
    table.insert(sum, slots[1]) -- insert the first slot into inputs and remove it so we don't double-count the first slot
    table.remove(slots,1)
    --interate through the remaining slots and see if the sum table already has the item listed
    for _,slot in pairs(slots) do
        local found = false          
        for i = 1, #sum do
          if (slot.type == sum[i].type) then --we've found the item exists so just add the new count and bump up the max for that item type
            found = true
            sum[i].count = sum[i].count + slot.count
            sum[i].max = sum[i].max + slot.max          
            --print ("Added "..slot.count.." "..slot.type.." New total: "..sum[i].count.." New max: "..sum[i].max)
          end          
        end
        if not found then --if the item wasn't found, we need to add a new "row" to our sum table with just this slot's properties
          table.insert(sum,{type=slot.type, count=slot.count, fill=slot.fill, max=slot.max})
          --print ("Inserted "..slot.type.." "..slot.count.." "..slot.fill.." "..slot.max)        
        end      
    end
    --update the aggregate fills
    if #sum > 1 then --more than one type of inventory. Calculate fill based on slots containing item / total capacity of those slots
      for _,item in pairs(sum) do
        item.fill = math.floor(item.count / item.max * 100) --floor because we just want an integer percentage (avoids string format issues)
      end  
    else --there is only one type of item.  Let's determine the total capacity assuming all slots were filled        
      sum[1].fill = math.floor(sum[1].count/(stackmax*outputslots)*100)
    end
    
    --For all slots that contain an item, we know the max but can only calculate the percent full for those slots
    --Need a special case when the table is purely one item, but not full so we can accurately report the fill of an entire container.
    
    return sum
  end
   
  function InventoryMachine(building)
    -- Machines all have inputs and outputs in two inventory groups. Group 1 is inputs, and group 2 is outputs.
    -- For machines with more than on input, each is just a slot like they are for containers
    -- When the machine has fluid and solid inputs, the fluid slots are x1000 units, so we need to check what we're inventorying
    
    --we're going to structure everything that is returned as input and output tables structured like this:
    -- input[itemtypename] = {qty, fill}
    local inputs = {}
    local outputs = {}
    local shards = 0 --may also be used to report batteries on a drone port?
    local istack
    local divisor = 1
    local stsize = 1
    local ingname = {}
    local norecipe = {"Container","DroneStation","Power","Tank","Train","Truck"} --buildings without receipes
    local cantInventory = {"Power","Valve"}
   
    --if you can't inventory the object, return without doing anything
    local ok2go = true
    for _,noinv in pairs(cantInventory) do
      if(string.match(building.internalName, noinv)) then return end
    end
    --attempting to access recipe of buildings that don't have one results in nil evaluation. Determine if this is one of those buildings without recipe.
    local hasrecipe = true
    for _,norec in pairs(norecipe) do
      if(string.match(building.internalName, norec)) then
        hasrecipe = false
      end
    end
    if(hasrecipe) then --get the current recipe and the list of ingredients
    local recipeobj = building:getRecipe()
      if(recipeobj ~= nil) then --we are dealing with a machine that has an active receipe
        local ingreds = recipeobj:getIngredients()
        --print("Building IngName Table")
        for _,ingred in pairs(ingreds) do
          table.insert(ingname,ingred.type.name)
          --print(#ingname,ingred.type.name)
        end
      
      end
    end
    --here we might be able to use the presence of a receipe to determine whether to loop to 3 (machine or drone/truck dock or 1 (container or fluid buffer)
   
    for i=1,3 do --machines have 3 types of inventory: inputs=1, outputs=2, and power shards=3
      local inv = building:getInventories()[i]
      
      if (inv ~= nil) then --can't find the type of inventory defined by i (1=inputs, 2=outputs, 3=shards) on this machine. Skip this type and continue the for loop 
        if (i==1) then --for inputs, each slot is a separate input item
   
          for x=0,inv.size-1 do --this is the number of input slots          
            istack = inv:getstack(x)
            if(istack.count > 0) then --check if there is something on the stack before atteempting to count or get stack size
              stsize = istack.item.type.max  
              if isFluid(istack.item.type.name) then
                divisor = 1000
              else
                divisor = 1
              end --if else
              --print("type: ",istack.item.type.name,"count: ",istack.count, "divisor: ",divisor,"stsize: ",stsize)  
              table.insert(inputs,{type=istack.item.type.name, count=istack.count/divisor, fill=math.floor(istack.count/stsize*100), max=stsize})
              --TEST: print ("input: "..istack.item.type.name)         
            end -- if
          end --for
   
        elseif (i==2) then --outputs include either single output machines, or all the slots of storage containers or docks
          
          for x=0,inv.size-1 do --this is the number of output slots          
            istack = inv:getstack(x)
            outputslots = inv.size
            if(istack.count > 0) then --check if there is something on the stack before atteempting to count or get stack size
              stsize = istack.item.type.max  
              if isFluid(istack.item.type.name) then
                divisor = 1000
              else
                divisor = 1
              end --if else
              --print("type: ",istack.item.type.name,"count: ",istack.count, "divisor: ",divisor,"stsize: ",stsize)  
              table.insert(outputs,{type=istack.item.type.name, count=istack.count/divisor, fill=math.floor(istack.count/stsize*100), max=stsize})
              --TEST: print ("Output: "..istack.item.type.name)         
            end -- if
          end --for
   
        elseif (i==3) then --shards
          
          istack = inv:getstack(0) -- there is only one shard stack
          shards = istack.count --shards are solids so we don't have to determine if it is fluid
   
        end --if elseif
      end --if
    end --for
    --before returning the inputs, add any ingredients to the list that were 0 then sort it alphabetically
    if (#ingname > 0) then --let's make sure all the receipe items are present, even if there were 0 in stock
      --print("Removing ingnames already inventoried")
      for _,input in pairs(inputs) do --remove any items we've inventoried, leaving only uninventoried ingredients      
        for i=1,#ingname do
          --print("Input type", input.type, "Ingname",ingname[i])        
          if (input.type == ingname[i]) then
            --print("removing: "..ingname[i])
            table.remove(ingname,i)
          end --if        
        end --for ingname      
      end --for input
      --print("ingname now has "..#ingname.." elements")
      --now let's add any recipe items that had no inventory to the inputs list
      for _,ing in pairs(ingname) do
        table.insert(inputs,{type=ing, count=0, fill=0, max=0})
      end --for
      for _,inp in pairs(inputs) do
        print(inp.type, inp.count, inp.fill, inp.max)
      end
      --finally let's sort this alphabetically by item (type)
      --table.sort(inputs,Compare)
      table.sort(inputs, function (a,b) return a.type < b.type end)
    end -- if
   
    --containers and other storage may have multiple slots containing the same item.
    --we just want the total of each type of item, so consoliate to unique items in output (not required for input)
    if not hasreceipe then --machines with recipes have only one output slot, so no need to consolidate
      outputs = AggregateSlots(outputs, outputslots) --this also doesn't work if there is just one slot
    end
   
    return inputs, outputs, shards  --last parameter also used for batteries on drone ports, fuel on truck stations
  end --function