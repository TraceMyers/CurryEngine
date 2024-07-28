#if USING_IMGUI ImGui :: #import "ImGui";

imgui_init :: () -> bool {
    #if USING_IMGUI then return imgui_init_impl();
    else return false;
}

imgui_deinit :: () {
    #if USING_IMGUI then imgui_deinit_impl();
}

imgui_new_frame :: () {
    #if USING_IMGUI {
        imgui_new_frame_impl();
        ImGui.NewFrame();
    }
}

imgui_render :: () {
    #if USING_IMGUI {
        ImGui.Render();
        imgui_render_impl();
    }
}

imgui_set_cursor :: () {
    #if USING_IMGUI {
        using context.curry.gui_data;
        if ImGui.GetMouseCursor() == {
            case .Arrow;         SDL_SetCursor(cursor_arrow);
            case .TextInput;     SDL_SetCursor(cursor_text_input);
            case .Hand;          SDL_SetCursor(cursor_move);
            case .ResizeNS;      SDL_SetCursor(cursor_resize_ns);
            case .ResizeEW;      SDL_SetCursor(cursor_resize_ew);
            case .ResizeNESW;    SDL_SetCursor(cursor_resize_nesw);
            case .ResizeNWSE;    SDL_SetCursor(cursor_resize_nwse);
        }
    }
}

imgui_get_clipboard_text :: (data: *void) -> *u8 #c_call {
    return SDL_GetClipboardText();
}

imgui_set_clipboard_text :: (data: *void, text: *u8) #c_call {
    SDL_SetClipboardText(text);
}

imgui_init_impl :: () -> bool {
    io := ImGui.GetIO();
    // Keyboard mapping. ImGui will use those indices to peek into the io.KeyDown[] array.
    io.KeyMap[ImGui.Key.Tab] = xx SDLK_TAB;                     
    io.KeyMap[ImGui.Key.LeftArrow] = xx SDL_SCANCODE_LEFT;
    io.KeyMap[ImGui.Key.RightArrow] = xx SDL_SCANCODE_RIGHT;
    io.KeyMap[ImGui.Key.UpArrow] = xx SDL_SCANCODE_UP;
    io.KeyMap[ImGui.Key.DownArrow] = xx SDL_SCANCODE_DOWN;
    io.KeyMap[ImGui.Key.PageUp] = xx SDL_SCANCODE_PAGEUP;
    io.KeyMap[ImGui.Key.PageDown] = xx SDL_SCANCODE_PAGEDOWN;
    io.KeyMap[ImGui.Key.Home] = xx SDL_SCANCODE_HOME;
    io.KeyMap[ImGui.Key.End] = xx SDL_SCANCODE_END;
    io.KeyMap[ImGui.Key.Delete] = xx SDLK_DELETE;
    io.KeyMap[ImGui.Key.Backspace] = xx SDLK_BACKSPACE;
    io.KeyMap[ImGui.Key.Enter] = xx SDLK_RETURN;
    io.KeyMap[ImGui.Key.Escape] = xx SDLK_ESCAPE;
    io.KeyMap[ImGui.Key.A] = xx SDLK_a;
    io.KeyMap[ImGui.Key.C] = xx SDLK_c;
    io.KeyMap[ImGui.Key.V] = xx SDLK_v;
    io.KeyMap[ImGui.Key.X] = xx SDLK_x;
    io.KeyMap[ImGui.Key.Y] = xx SDLK_y;
    io.KeyMap[ImGui.Key.Z] = xx SDLK_z;

    io.SetClipboardTextFn = imgui_set_clipboard_text;
    io.GetClipboardTextFn = imgui_get_clipboard_text;
    io.ClipboardUserData = null;

    #if OS == .WINDOWS {
        wmInfo: SDL_SysWMinfo ;
        SDL_VERSION(*wmInfo.version);
        SDL_GetWindowWMInfo(context.curry.window, *wmInfo);
        io.ImeWindowHandle = wmInfo.info.win.window;
    }

    using context.curry.gui_data;

    cursor_arrow = SDL_CreateSystemCursor(.ARROW);
    cursor_text_input = SDL_CreateSystemCursor(.IBEAM);
    cursor_move = SDL_CreateSystemCursor(.HAND);
    cursor_resize_ns = SDL_CreateSystemCursor(.SIZENS);
    cursor_resize_ew = SDL_CreateSystemCursor(.SIZEWE);
    cursor_resize_nesw = SDL_CreateSystemCursor(.SIZENESW);
    cursor_resize_nwse = SDL_CreateSystemCursor(.SIZENWSE);

    ImGui.StyleColorsClassic();

    imgui_create_device_objects();

    initialized = xx true;
    return true;
}

imgui_create_device_objects :: () {
    using context.curry.gui_data;

    vertex_shader := #string END
        #version 330

        in vec2 Position;
        in vec2 UV;
        in vec4 Color;

        uniform mat4 ProjMtx;

        out vec2 Frag_UV;
        out vec4 Frag_Color;

        void main() {
           Frag_UV = UV;
           Frag_Color = Color;
           gl_Position = ProjMtx * vec4(Position.xy,0,1);
        }
    END

    fragment_shader := #string END
        #version 330

        uniform sampler2D Texture;

        in vec2 Frag_UV;
        in vec4 Frag_Color;

        out vec4 Out_Color;

        void main() {
           Out_Color = Frag_Color * texture( Texture, Frag_UV.st).r;
        }
    END

    shader = shader_create_vf(vertex_shader, fragment_shader);
    assert(!shader_invalid(*shader));

    vb = vertex_buffer_create_blank();
    ib = index_buffer_create_blank();
    va = vertex_array_create();
    vertex_array_add_buffer(*va, *vb, ImguiVertexType, shader.render_id, "Position", "UV", "Color");

    imgui_create_fonts_texture();
}

imgui_create_fonts_texture :: () {
    io := ImGui.GetIO();
    using context.curry.gui_data;
    bpp: s32;
    io.Fonts.GetTexDataAsAlpha8(io.Fonts, *font_texture.raw_data.data, *font_texture.width, *font_texture.height, *bpp);
    font_texture.pixel_tag = .R8;
    creation_info := TextureCreationInfo.{wrap_width=-1, wrap_height=-1, delete_local=false};
    texture_create_on_gpu(*font_texture, *creation_info);
    io.Fonts.TexID = xx font_texture.render_id;
}

imgui_deinit_impl :: () {
    using context.curry.gui_data;
    shader_delete(*shader);
    vertex_buffer_delete(*vb);
    index_buffer_delete(*ib);
    vertex_array_delete(*va);
    texture_delete(*font_texture);
    io := ImGui.GetIO();
    io.Fonts.TexID = null;
    ImGui.DestroyContext(imgui_context);
}

imgui_new_frame_impl :: () {
    using context.curry;
    io := ImGui.GetIO();

    width, height: s32;
    display_width, display_height: s32;
    SDL_GetWindowSize(window, *width, *height);
    SDL_GL_GetDrawableSize(window, *display_width, *display_height);
    // window_dims := window_settings.dimensions;
    io.DisplaySize = .{xx width, xx height};
    io.DisplayFramebufferScale = .{
        cast(float) display_width / width, cast(float) display_height / height
    };

    io.DeltaTime = delta_time;
    mx, my: s32;
    mouse_mask := SDL_GetMouseState(*mx, *my);
    if (SDL_GetWindowFlags(window) & SDL_WINDOW_MOUSE_FOCUS) {
        io.MousePos = .{xx mx, xx my};   // Mouse position, in pixels (set to -1,-1 if no mouse / on another screen, etc.)
    } else {
        io.MousePos = .{-FLOAT32_MAX,-FLOAT32_MAX};
    }

    io.MouseDown[0] = (mouse.buttons[0].down.fixed_state || (mouse_mask & SDL_BUTTON(SDL_BUTTON_LEFT)) != 0);
    io.MouseDown[1] = (mouse.buttons[1].down.fixed_state || (mouse_mask & SDL_BUTTON(SDL_BUTTON_RIGHT)) != 0);
    io.MouseDown[2] = (mouse.buttons[2].down.fixed_state || (mouse_mask & SDL_BUTTON(SDL_BUTTON_MIDDLE)) != 0);

    io.MouseWheel = gui_data.mouse_wheel;

    SDL_ShowCursor(xx (io.MouseDrawCursor == false));
}

imgui_render_impl :: () {
    using context.curry;
    graphics_settings: GraphicsAPISettings = ---;
    cache_graphics_api_settings(*graphics_settings);
    #if GRAPHICS_API == .OPENGL {
        imgui_opengl_render();
    }
    set_graphics_api_settings(*graphics_settings);
}
