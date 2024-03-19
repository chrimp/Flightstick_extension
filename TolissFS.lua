planes_ICAO = ["A319", "A20N", "A321", "A21N"]

local is_supported = false
for i = 1, #planes_ICAO do
    if PLANE_ICAO == planes_ICAO[i] then
        is_supported = true
        break
    end
end


if is_supported and PLANE_AUTHOR == "Gliding Kiwi" then

    set("toliss_airbus/joystick/throttle/mctDetentRatio", 1.0)

    local listen_thr = false --toga_event_handler()
    local listen_splr = false --splr_event_handler()
    local last_ctrl = "" --check_last_button()
    local last_axis_wheel = nil --get_axis_change()
    local glb_axis_change = 0 
    local ignore_next_frame = false --change_variable()
    local is_trim_moving = 0 --0 = not moving, 1 = moving up, -1 = moving down | end_trim_command()
    local trim_start_time = 0 --end_trim_command()
    local button_disabled = false --disable_adjacent_buttons()
    local wheel_move_time = 0 --disable_adjacent_buttons()
    local binding_335 = "" --get_btn_assignments()
    local binding_336 = "" --get_btn_assignments()

    function get_datarefs()
        DataRef("axis_wheel", "sim/joystick/joystick_axis_values", "readonly", 52)
        DataRef("speed", "sim/cockpit/autopilot/airspeed", "writable")
        DataRef("heading", "sim/cockpit/autopilot/heading_mag", "writable")
        DataRef("altitude", "sim/cockpit/autopilot/altitude", "writable")
        DataRef("vertical_speed", "sim/cockpit/autopilot/vertical_velocity", "writable")
        DataRef("time", "flight_time", "readonly")
        return
    end

    function get_btn_assignments()
        local path = SYSTEM_DIRECTORY .. "Output/preferences/X-Plane Joystick Settings.prf"
        local binding_164 = "" --button 335
        local binding_165 = "" --button 336
        for line in io.lines(path) do
            if line:find("_joy_BUTN_use164 ") then
                binding_164 = line:gsub("_joy_BUTN_use164 ", "")
            end
            if line:find("_joy_BUTN_use165 ") then
                binding_165 = line:gsub("_joy_BUTN_use165 ", "")
            end
        end
        return binding_164, binding_165
    end

    function toga_event_handler()
        if button(328) then
            listen_thr = true
        end
        if not button(328) and listen_thr then
            set_array("AirbusFBW/throttle_input", 0, 0.88)
            set_array("AirbusFBW/throttle_input", 1, 0.88)
            listen_thr = false
        end
    
        return
    end
    
    function splr_event_handler()
        if button(330) then
            listen_splr = true
        end
        if not button(330) and listen_splr then
            command_once("sim/flight_controls/speed_brakes_up_all")
            listen_splr = false
        end
    
        return
    end

    function check_last_button()
        if button(320) then
            last_ctrl = "speed"
        elseif button(321) then
            last_ctrl = "hdg"
        elseif button(322) then
            last_ctrl = "alt"
        elseif button(323) then
            last_ctrl = "vs"
        elseif button(338) then
            last_ctrl = "elv_trim"
        end
    end

    function get_axis_change()
        if last_axis_wheel == nil then
            last_axis_wheel = axis_wheel
            glb_axis_change = 0
            return
        end
        local axis_change = axis_wheel - last_axis_wheel
        last_axis_wheel = axis_wheel
        axis_change = axis_change * -1
        glb_axis_change = axis_change
        return
    end

    function change_variable()
        if ignore_next_frame then
            ignore_next_frame = false
            return
        end
        if glb_axis_change == 0 then
            return
        end
        if math.abs(glb_axis_change) < 0.001 then
            ignore_next_frame = true
        end
        if last_ctrl == "speed" then
            local last_speed = speed
            local new_speed = 0
            if glb_axis_change < 0 then
                new_speed = math.ceil(glb_axis_change * 1040)
            else
                new_speed = math.floor(glb_axis_change * 1040)
            end
            speed = last_speed + new_speed
        elseif last_ctrl == "hdg" then
            local last_heading = heading
            local new_heading = 0
            if glb_axis_change < 0 then
                new_heading = math.ceil(glb_axis_change * 1040)
            else
                new_heading = math.floor(glb_axis_change * 1040)
            end
            heading = last_heading + new_heading
        elseif last_ctrl == "alt" then
            local last_alt = altitude
            local new_alt = 0
            if glb_axis_change < 0 then
                new_alt = math.ceil(glb_axis_change * 1040) * 1000
            else
                new_alt = math.floor(glb_axis_change * 1040) * 1000
            end
            altitude = last_alt + new_alt
        elseif last_ctrl == "vs" then
            local last_vs = vertical_speed
            local new_vs = 0
            if glb_axis_change < 0 then
                new_vs = math.ceil(glb_axis_change * 1040) * 100
            else
                new_vs = math.floor(glb_axis_change * 1040) * 100
            end
            vertical_speed = last_vs + new_vs
        elseif last_ctrl == "elv_trim" then
            if glb_axis_change > 0 then
                if is_trim_moving == -1 then
                    command_end("sim/flight_controls/pitch_trim_down")
                end
                is_trim_moving = 1
                command_begin("sim/flight_controls/pitch_trim_up")
                trim_start_time = time
            elseif glb_axis_change < 0 then
                if is_trim_moving == 1 then
                    command_end("sim/flight_controls/pitch_trim_up")
                end
                is_trim_moving = -1
                command_begin("sim/flight_controls/pitch_trim_down")
                trim_start_time = time
            end
        end
    end

    function end_trim_command()
        local current_time = time
        if glb_axis_change == 0 and (current_time - trim_start_time >= 0.5) then
            if is_trim_moving == 1 then
                command_end("sim/flight_controls/pitch_trim_up")
            elseif is_trim_moving == -1 then
                command_end("sim/flight_controls/pitch_trim_down")
            end
        elseif last_ctrl ~= "elv_trim" then
            if is_trim_moving == 1 then
                command_end("sim/flight_controls/pitch_trim_up")
            elseif is_trim_moving == -1 then
                command_end("sim/flight_controls/pitch_trim_down")
            end
        end
    end

    function knob_push_pull()
        if last_ctrl == "speed" then
            if button(340) then
                command_once("AirbusFBW/PushSPDSel")
            elseif button(342) then
                command_once("AirbusFBW/PullSPDSel")
            end
        elseif last_ctrl == "hdg" then
            if button(340) then
                command_once("AirbusFBW/PushHDGSel")
            elseif button(342) then
                command_once("AirbusFBW/PullHDGSel")
            end
        elseif last_ctrl == "alt" then
            if button(340) then
                command_once("AirbusFBW/PushAltitude")
            elseif button(342) then
                command_once("AirbusFBW/PullAltitude")
            end
        elseif last_ctrl == "vs" then
            if button(340) then
                command_once("toliss_airbus/vs_push")
            elseif button(342) then
                vertical_speed = 0
            end
        end
    end

    function disable_adjacent_buttons()
        local current_time = time
        if glb_axis_change ~= 0 and not button_disabled then
            wheel_move_time = time
            button_disabled = true
            set_button_assignment(335, "sim/none/none")
            set_button_assignment(336, "sim/none/none")
        elseif glb_axis_change == 0 and button_disabled then
            if current_time - wheel_move_time >= 3 then
                button_disabled = false
                set_button_assignment(335, binding_335)
                set_button_assignment(336, binding_336)
            end
        end
    end
    
    get_datarefs()
    binding_335, binding_336 = get_btn_assignments()

    do_every_frame("toga_event_handler()")
    do_every_frame("disable_adjacent_buttons()")
    do_every_frame("check_last_button()")
    do_every_frame("change_variable()")
    do_every_frame("knob_push_pull()")
    do_every_frame("end_trim_command()")
    do_every_frame("get_axis_change()")
    do_often("splr_event_handler()")
    
end
