-- overlay_gpu.lua - Lua wrapper for the GPU overlay DLL
-- generated with claude.ai


local ffi = require("ffi")
-- Load the DLL
local overlay_dll = ffi.load("./overlaygpu.dll")

ffi.cdef[[
    void Sleep(int ms);
    int poll(struct pollfd *fds, unsigned long nfds, int timeout);
]]

os.sleep = function(sec)
    ffi.C.Sleep(sec * 1000) -- Convert seconds to milliseconds
end

-- Function declarations - Updated for GPU version
ffi.cdef[[
    int overlay_create(int width, int height, int alpha);
    void overlay_begin_draw();
    void overlay_end_draw();
    void overlay_clear(int r, int g, int b, int a);
    void overlay_draw_line(int x1, int y1, int x2, int y2, int r, int g, int b, int thickness);
    void overlay_draw_rectangle(int x, int y, int width, int height, int r, int g, int b, int filled);
    void overlay_draw_circle(int x, int y, int radius, int r, int g, int b, int filled);
    void overlay_draw_text(int x, int y, const char* text, int r, int g, int b);
    void overlay_update();
    int overlay_is_running();
    void overlay_set_alpha(int alpha);
    void overlay_cleanup();
    void overlay_test_draw();
]]

-- Overlay class
local Overlay = {}
Overlay.__index = Overlay

function Overlay:new(width, height, alpha)
    local self = setmetatable({}, Overlay)
    self.width = width or 800
    self.height = height or 600
    self.alpha = alpha or 200
    return self
end

function Overlay:create()
    local result = overlay_dll.overlay_create(self.width, self.height, self.alpha)
    return result == 1
end

function Overlay:beginDraw()
    overlay_dll.overlay_begin_draw()
end

function Overlay:endDraw()
    overlay_dll.overlay_end_draw()
end

-- Updated to match GPU version signature (4 parameters)
function Overlay:clear(r, g, b, a)
    r = r or 0  -- Default to black
    g = g or 0  -- Default to black  
    b = b or 0  -- Default to black
    a = a or 0  -- Default to transparent
    overlay_dll.overlay_clear(r, g, b, a)
end

function Overlay:drawLine(x1, y1, x2, y2, r, g, b, thickness)
    r = r or 255
    g = g or 255
    b = b or 255
    thickness = thickness or 1
    overlay_dll.overlay_draw_line(x1, y1, x2, y2, r, g, b, thickness)
end

function Overlay:drawRectangle(x, y, width, height, r, g, b, filled)
    r = r or 255
    g = g or 255
    b = b or 255
    filled = filled and 1 or 0
    overlay_dll.overlay_draw_rectangle(x, y, width, height, r, g, b, filled)
end

function Overlay:drawCircle(x, y, radius, r, g, b, filled)
    r = r or 255
    g = g or 255
    b = b or 255
    filled = filled and 1 or 0
    overlay_dll.overlay_draw_circle(x, y, radius, r, g, b, filled)
end

function Overlay:drawText(x, y, text, r, g, b)
    r = r or 255
    g = g or 255
    b = b or 255
    overlay_dll.overlay_draw_text(x, y, text, r, g, b)
end

function Overlay:update()
    overlay_dll.overlay_update()
end

function Overlay:isRunning()
    return overlay_dll.overlay_is_running() == 1
end

function Overlay:setAlpha(alpha)
    overlay_dll.overlay_set_alpha(alpha)
end

function Overlay:cleanup()
    overlay_dll.overlay_cleanup()
end

function Overlay:testDraw()
    overlay_dll.overlay_test_draw()
end

function Overlay:run()
    if not self:create() then
        print("Failed to create overlay window")
        return false
    end
    
    print("GPU Overlay created. Press ESC to exit.")
    
    -- Main loop
    while self:isRunning() do
        -- Begin GPU drawing context
        self:beginDraw()
        
        -- Clear to transparent
        self:clear(0, 0, 0, 0)  -- Transparent background
        
        -- Draw some example shapes
        self:drawLine(50, 50, 200, 200, 255, 0, 0, 3)      -- Red line
        self:drawRectangle(300, 100, 150, 100, 0, 255, 0, false)  -- Green outline rectangle
        self:drawRectangle(350, 120, 50, 60, 0, 0, 255, true)     -- Blue filled rectangle
        self:drawCircle(500, 300, 50, 255, 255, 0, true)          -- Yellow filled circle
        self:drawCircle(600, 300, 40, 255, 0, 255, false)         -- Magenta outline circle
        self:drawText(100, 400, "GPU Lua Overlay - Press ESC to exit", 255, 255, 255)  -- White text
        
        -- End GPU drawing context (this presents to screen)
        self:endDraw()
        
        -- Update the overlay (process messages)
        self:update()
        
        -- Small delay to prevent excessive CPU usage (16ms ≈ 60fps)
        os.sleep(0.016) -- 16ms for 60fps
    end
    
    self:cleanup()
    print("GPU Overlay closed.")
    return true
end

-- Simple test function using the built-in test draw
function Overlay:runSimpleTest()
    if not self:create() then
        print("Failed to create overlay window")
        return false
    end
    
    print("GPU Overlay Test - Press ESC to exit.")
    
    while self:isRunning() do
        self:testDraw()  -- Use the built-in test function
        self:update()
        os.sleep(0.016)
    end
    
    self:cleanup()
    return true
end

function Overlay:runSpinningAnimation(fps)
    if not self:create() then
        print("Failed to create overlay window")
        return false
    end
    
    fps = fps or 165
    local frame_time = 1.0 / fps
    print(string.format("GPU Overlay Spinning Animation @ %d Hz - Press ESC to exit.", fps))
    
    local time = 0
    local frame_count = 0
    local start_time = os.clock()
    
    -- Animation parameters
    local center_x = self.width / 2
    local center_y = self.height / 2
    local orbit_radius = 150
    local spinner_radius = 30
    local num_spinners = 6
    
    while self:isRunning() do
        local frame_start = os.clock()
        
        -- Begin GPU drawing context
        self:beginDraw()
        
        -- Clear to transparent
        self:clear(0, 0, 0, 0)
        
        -- Calculate rotation angles
        local main_angle = time * 2 -- Main rotation speed
        local spinner_angle = time * 8 -- Individual spinner rotation speed
        
        -- Draw center circle
        self:drawCircle(center_x, center_y, 10, 255, 255, 255, true)
        
        -- Draw orbiting spinners
        for i = 0, num_spinners - 1 do
            local base_angle = (i * 2 * math.pi / num_spinners) + main_angle
            
            -- Calculate orbiting position
            local orbit_x = center_x + math.cos(base_angle) * orbit_radius
            local orbit_y = center_y + math.sin(base_angle) * orbit_radius
            
            -- Color cycling based on position and time
            local hue = (i / num_spinners + time * 0.5) % 1
            local r = math.floor(255 * (0.5 + 0.5 * math.cos(hue * 2 * math.pi)))
            local g = math.floor(255 * (0.5 + 0.5 * math.cos((hue + 0.33) * 2 * math.pi)))
            local b = math.floor(255 * (0.5 + 0.5 * math.cos((hue + 0.66) * 2 * math.pi)))
            
            -- Draw main spinner circle
            self:drawCircle(orbit_x, orbit_y, spinner_radius, r, g, b, true)
            
            -- Draw spinning lines inside each spinner
            for j = 0, 3 do
                local line_angle = spinner_angle + (j * math.pi / 2)
                local line_length = spinner_radius * 0.8
                
                local x1 = orbit_x + math.cos(line_angle) * line_length
                local y1 = orbit_y + math.sin(line_angle) * line_length
                local x2 = orbit_x - math.cos(line_angle) * line_length
                local y2 = orbit_y - math.sin(line_angle) * line_length
                
                self:drawLine(x1, y1, x2, y2, 255, 255, 255, 2)
            end
            
            -- Draw orbit trail (fading effect)
            local trail_steps = 20
            for t = 1, trail_steps do
                local trail_angle = base_angle - (t * 0.1)
                local trail_x = center_x + math.cos(trail_angle) * orbit_radius
                local trail_y = center_y + math.sin(trail_angle) * orbit_radius
                
                -- Small fading circles for trail
                self:drawCircle(trail_x, trail_y, 3, r, g, b, true)
            end
        end
        
        -- Draw connecting lines between spinners
        for i = 0, num_spinners - 1 do
            local angle1 = (i * 2 * math.pi / num_spinners) + main_angle
            local angle2 = ((i + 1) % num_spinners * 2 * math.pi / num_spinners) + main_angle
            
            local x1 = center_x + math.cos(angle1) * orbit_radius
            local y1 = center_y + math.sin(angle1) * orbit_radius
            local x2 = center_x + math.cos(angle2) * orbit_radius
            local y2 = center_y + math.sin(angle2) * orbit_radius
            
            self:drawLine(x1, y1, x2, y2, 100, 100, 100, 1)
        end
        
        -- Draw performance info
        local elapsed = os.clock() - start_time
        local current_fps = frame_count / elapsed
        local info_text = string.format("GPU Overlay @ %.1f FPS | Target: %d Hz | Time: %.1fs", 
                                       current_fps, fps, elapsed)
        self:drawText(10, 10, info_text, 255, 255, 0)
        
        -- Draw frame counter
        self:drawText(10, 30, string.format("Frame: %d", frame_count), 200, 200, 200)
        
        -- End GPU drawing context (this presents to screen)
        self:endDraw()
        
        -- Update the overlay (process messages)
        self:update()
        
        -- Frame timing
        frame_count = frame_count + 1
        time = time + frame_time
        
        -- Precise timing for target FPS
        local frame_duration = os.clock() - frame_start
        local sleep_time = frame_time - frame_duration
        
        if sleep_time > 0 then
            os.sleep(sleep_time)
        end
    end
    
    local total_time = os.clock() - start_time
    local actual_fps = frame_count / total_time
    print(string.format("Animation finished. Rendered %d frames in %.2f seconds (%.1f FPS average)", 
                       frame_count, total_time, actual_fps))
    
    self:cleanup()
    return true
end

-- Usage example
local function main()
    print("Creating GPU Lua Overlay with Spinning Animation...")
    
    local overlay = Overlay:new(800, 800, 250) -- 800x600, semi-transparent
    
    -- Run the spinning animation at 165Hz
    overlay:runSpinningAnimation(120)
end

-- Run if this file is executed directly
if not pcall(debug.getlocal, 4, 1) then
    main()
end

-- Export the Overlay class
return Overlay