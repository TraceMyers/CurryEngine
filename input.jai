SwitchCode :: enum u64 {
    MOUSE       :: 0x0000000100000000;
    KEYBOARD    :: 0x0000000200000000;
    GAMEPAD     :: 0x0000000400000000;
    // todo: use metaprogramming to bring SDL codes into lower 32 bits
}

SwitchFlags :: struct {
    fixed_state : bool;
    consumable_state: bool;
}

SwitchConsumeSetting :: enum u8 {
    NONE        :: 0x00;
    DOWN        :: 0x01;
    PRESSED     :: 0x02;
    RELEASED    :: 0x04;
}

SwitchInput :: struct {
    down : SwitchFlags;
    just_pressed : SwitchFlags;
    just_released : SwitchFlags;
    down_consume := SwitchConsumeSetting.DOWN;
    pressed_consume := SwitchConsumeSetting.PRESSED;
    released_consume := SwitchConsumeSetting.RELEASED;
    no_input_counter : u8;
}

SwitchReading :: struct {
    down: bool;
    up: bool;
}

MouseWheelState :: enum u8 {
    SCROLLING_UP;
    SCROLLING_DOWN;
    NOT_SCROLLING;
}

MouseState :: struct {
    left: SwitchInput;
    right: SwitchInput;
    middle: SwitchInput;
    wheel: MouseWheelState;
    using window_position: IntVector2;

#place left;
    buttons: [3]SwitchInput;

    MOUSE_LEFT :: 0;
    MOUSE_RIGHT :: 1;
    MOUSE_MIDDLE :: 2;
}

INVALID_MOUSE_POSITION :: IntVector2.{-1, -1};

mouse_window_position_invalid :: () -> bool {
    return mouse.window_position == INVALID_MOUSE_POSITION;
}

// TODO: bring over zig implementation that with multiple 'player/controller' support and bindings
mouse: MouseState;
switches: [SDL_NUM_SCANCODES]SwitchInput;

update_input :: (curry: *Curry) {
    SCANCODE_MASK :: ~(1<<30);

    switch_readings: [SDL_NUM_SCANCODES]SwitchReading;
    mouse_readings: [3]SwitchReading;
    #if INCLUDE_IMGUI imgui_io := ImGui.GetIO();

    mouse.wheel = .NOT_SCROLLING;

    event: SDL_Event;
    while SDL_PollEvent(*event) {
        if event.type == {
        case SDL_QUIT;
            curry.quit = true;
        case SDL_MOUSEWHEEL;
            if event.wheel.y > 0 then mouse.wheel = .SCROLLING_UP;
            if event.wheel.y < 0 then mouse.wheel = .SCROLLING_DOWN;
        case SDL_MOUSEBUTTONDOWN; #through;
        case SDL_MOUSEBUTTONUP;
            button_index := -1;
            if event.button.button == {
            case SDL_BUTTON_LEFT; button_index = MouseState.MOUSE_LEFT;
            case SDL_BUTTON_RIGHT; button_index = MouseState.MOUSE_RIGHT;
            case SDL_BUTTON_MIDDLE; button_index = MouseState.MOUSE_MIDDLE;
            }
            if button_index >= 0 {
                if event.type == SDL_MOUSEBUTTONDOWN
                    then mouse_readings[button_index].down = true;
                    else mouse_readings[button_index].up = true;
            }
        case SDL_TEXTINPUT;
            #if INCLUDE_IMGUI {
                if curry.frame_count == 0 then continue;
                imgui_io.AddInputCharactersUTF8(imgui_io, xx event.text.text.data);
            }
        case SDL_KEYDOWN; #through;
        case SDL_KEYUP;
            if event.key.keysym.sym == SDLK_ESCAPE
                then curry.quit = true;

            key := event.key.keysym.sym & (xx SCANCODE_MASK);
            key_is_down := event.type == SDL_KEYDOWN;
            if key_is_down
                then switch_readings[xx key].down = true;
                else switch_readings[xx key].up = true;

            // TODO: handle modifiers outside of ImGui
            #if INCLUDE_IMGUI {
                if curry.frame_count == 0 then continue;
                imgui_io.KeysDown[key] = key_is_down;
                kmod := SDL_GetModState();
                imgui_io.KeyShift = ((kmod & KMOD_SHIFT) != 0);
                imgui_io.KeyCtrl = ((kmod & KMOD_CTRL) != 0);
                imgui_io.KeyAlt = ((kmod & KMOD_ALT) != 0);
                imgui_io.KeySuper = ((kmod & KMOD_GUI) != 0);
            }
        }
    }

    #if INCLUDE_IMGUI {
        if mouse.wheel == {
        case .NOT_SCROLLING;
            curry.gui_data.mouse_wheel = 0.0;
        case .SCROLLING_UP;
            curry.gui_data.mouse_wheel = 1.0;
        case .SCROLLING_DOWN;
            curry.gui_data.mouse_wheel = -1.0;
        }
    }

    for switch_readings {
        set_switch(*switches[it_index], it);
    }
    for i : 0..2 {
        set_switch(*mouse.buttons[i], mouse_readings[i]);
    }
}

set_switch :: inline (using switch: *SwitchInput, reading: SwitchReading) {
    was_down := down.fixed_state;
    if reading.up {
        down.fixed_state = false;
        just_pressed.fixed_state = false;
        if was_down
            then just_released.fixed_state = true;
            else just_released.fixed_state = false;
        no_input_counter = 0;
    } else if reading.down {
        down.fixed_state = true;
        if !was_down
            then just_pressed.fixed_state = true;
            else just_pressed.fixed_state = false;
        just_released.fixed_state = false;
        no_input_counter = 0;
    } else if just_pressed.fixed_state {
        just_pressed.fixed_state = false;
    } else if just_released.fixed_state {
        just_released.fixed_state = false;
    } else {
        // TODO: evaluate efficacy of erasing an input after some time
        // NOTE: this appears to occasionally just eat input
        // no_input_counter += 1;
        // if no_input_counter >= U8_MAX {
            // down.fixed_state = false;
            // just_pressed.fixed_state = false;
            // just_released.fixed_state = false;
            // no_input_counter = 0;
        // }
    }
    down.consumable_state = down.fixed_state;
    just_pressed.consumable_state = just_pressed.fixed_state;
    just_released.consumable_state = just_released.fixed_state;
}

// TODO: mouse, key, and gamepad button should all be gottne through these, so probably not SDK_Keycode
key_down :: inline (key: SDL_Keycode, use_consumable := false, do_consume := false) -> bool {
    switch := *switches[xx key];
    if do_consume {
        consumed_state := switch.down.consumable_state;
        consume_switch(switch, switch.down_consume);
        if use_consumable then return consumed_state;
    } else if use_consumable {
        return switch.down.consumable_state;
    } 
    return switch.down.fixed_state;
}

key_just_pressed :: inline (key: SDL_Keycode, use_consumable := false, do_consume := false) -> bool {
    switch := *switches[xx key];
    if do_consume {
        consumed_state := switch.just_pressed.consumable_state;
        consume_switch(switch, switch.pressed_consume);
        if use_consumable then return consumed_state;
    } else if use_consumable {
        return switch.just_pressed.consumable_state;
    }
    return switch.just_pressed.fixed_state;
}

key_just_released :: inline (key: SDL_Keycode, use_consumable := false, do_consume := false) -> bool {
    switch := *switches[xx key];
    if do_consume {
        consumed_state := switch.just_released.consumable_state;
        consume_switch(switch, switch.released_consume);
        if use_consumable then return consumed_state;
    } else if use_consumable{
        return switch.just_released.consumable_state;
    }
    return switch.just_released.fixed_state;
}

consume_switch :: inline (using switch: *SwitchInput, settings: SwitchConsumeSetting) {
    if settings & .DOWN then down.consumable_state = false;
    if settings & .PRESSED then just_pressed.consumable_state = false;
    if settings & .RELEASED then just_released.consumable_state = false;
}


