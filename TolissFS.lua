if PLANE_ICAO == "A20N" and PLANE_AUTHOR == "Gliding Kiwi" then

    local listen_thr = false
    local listen_splr = false
    local last_ctrl = ""

    DataRef("axis_wheel", "sim/joystick/joystick_axis_values", "readonly", 52)
    DataRef("speed", "sim/cockpit/autopilot/airspeed", "writable")
    DataRef("heading", "sim/cockpit/autopilot/heading_mag", "writable")
    DataRef("altitude", "sim/cockpit/autopilot/altitude", "writable")
    DataRef("vertical_speed", "sim/cockpit/autopilot/vertical_velocity", "writable")
    local last_axis_wheel

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
        end
    end

    function get_axis_change()
        if last_axis_wheel == nil then
            last_axis_wheel = axis_wheel
            return 0
        end
        local axis_change = axis_wheel - last_axis_wheel
        last_axis_wheel = axis_wheel
        axis_change = axis_change * -1
        return axis_change
    end

    local ignore_next_frame = false

    function change_variable()
        local axis_change = get_axis_change()
        if ignore_next_frame then
            ignore_next_frame = false
            return
        end
        if axis_change == 0 then
            return
        end
        if math.abs(axis_change) < 0.001 then
            ignore_next_frame = true
        end
        if last_ctrl == "speed" then
            local last_speed = speed
            local new_speed = 0
            if axis_change < 0 then
                new_speed = math.ceil(axis_change * 1040)
            else
                new_speed = math.floor(axis_change * 1040)
            end
            speed = last_speed + new_speed
        elseif last_ctrl == "hdg" then
            local last_heading = heading
            local new_heading = 0
            if axis_change < 0 then
                new_heading = math.ceil(axis_change * 1040)
            else
                new_heading = math.floor(axis_change * 1040)
            end
            heading = last_heading + new_heading
        elseif last_ctrl == "alt" then
            local last_alt = altitude
            local new_alt = 0
            if axis_change < 0 then
                new_alt = math.ceil(axis_change * 1040) * 1000
            else
                new_alt = math.floor(axis_change * 1040) * 1000
            end
            altitude = last_alt + new_alt
        elseif last_ctrl == "vs" then
            local last_vs = vertical_speed
            local new_vs = 0
            if axis_change < 0 then
                print("vs changed")
                new_vs = math.ceil(axis_change * 1040) * 100
            else
                print("vs changed")
                new_vs = math.floor(axis_change * 1040) * 100
            end
            vertical_speed = last_vs + new_vs
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
                command_once("AirbusFBW/PullVSSel")
            end
        end
    end

    set("toliss_airbus/joystick/throttle/mctDetentRatio", 1.0)
    do_every_frame("toga_event_handler()")
    do_every_frame("splr_event_handler()")
    do_every_frame("check_last_button()")
    do_every_frame("change_variable()")
    do_every_frame("knob_push_pull()")
end
