function calculate_trend(data)
    if #data ~= 10 then
        error("Data must contain exactly 10 points")
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

    return slope, intercept
end

-- Example usage
local data_points = {5, 6, 7, 8, 10, 11, 13, 14, 15, 18}
local slope, intercept = calculate_trend(data_points)

print("Slope:", slope)
print("Intercept:", intercept)
