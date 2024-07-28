WINDOW_SETTINGS_FILE_PATH :: "window_settings.txt";

HACKY_HIGH_RES_TIMER_RESOLUTION_MS :: 0.65;

// TODO: should probably just store allocator or pointer to allocator. for STBI, make an allocator that
// uses stbi functions.
AllocatorTag :: enum {
    NONE;
    DEFAULT;
    STBI;
}

force_cast :: (c: *$InStruct, $ToType: Type) -> *ToType #expand {
    return cast,force(*ToType) c;
}

deref_Any :: (val: Any, $ToType: Type) -> ToType #expand {
    return <<cast(*ToType) val.value_pointer;
}

ContextCurry :: struct {
    using #as base: Context_Base;
    using curry: Curry;
}

GraphicsAPI :: enum {
    OPENGL;
    VULKAN;
}

MeshDrawData :: struct {
    shader: Shader;
    va: VertexArray;
    vb: VertexBuffer;
    ib: IndexBuffer;
}

WindowSettings :: struct {
    width: s32 = 1280;
    height: s32 = 720;
    position_x: s32 = 10;
    position_y: s32 = 40;
    fullscreen := false;
    clear_color_r : float32;
    clear_color_g : float32;
    clear_color_b : float32;

    #place clear_color_r;
        clear_color: Color3f = ---;
    #place width;
        dimensions: IntVector2 = ---;
}

#if USING_IMGUI {
    GuiData :: struct {
        imgui_context: *ImGui.ImGuiContext;
        mouse_pressed := bool.[false, false, false];
        mouse_wheel: float = 0.0;
        font_texture: Texture;
        ImguiVertexType :: Vertex(2, .UV_2F, .COLOR_4B);
        shader: Shader;
        va: VertexArray;
        vb: VertexBuffer;
        ib: IndexBuffer;
        cursor_arrow: *SDL_Cursor;
        cursor_text_input: *SDL_Cursor;
        cursor_move: *SDL_Cursor;
        cursor_resize_ns: *SDL_Cursor;
        cursor_resize_ew: *SDL_Cursor;
        cursor_resize_nesw: *SDL_Cursor;
        cursor_resize_nwse: *SDL_Cursor;
        initialized : u8 = 0;
    }
}

UserProc :: #type ();

run_user_proc :: (p: UserProc) #expand {
    if p != null {
        if xx context.thread_index == context.curry.game_thread_id 
        || xx context.thread_index == context.curry.render_thread_id {
            p();
        } else assert(false);
    }
}

get_current_time :: () -> u64 {
    return SDL_GetPerformanceCounter();
}

time_since_frame_start :: () -> float32 {
    return time_since(context.curry.frame_start_time);
}

time_since :: (time_stamp: u64) -> float64 {
    frequency := SDL_GetPerformanceFrequency();
    current_time := SDL_GetPerformanceCounter();
    if time_stamp > 0 
        then return ((cast(float64)(current_time - time_stamp)) / frequency);
        else return 0.0;
}

do_sleep :: inline (milliseconds: float64, time_sensitive := false) {
    #if OS == .WINDOWS {
        windows_sleep_milliseconds(milliseconds, time_sensitive);
    }
}

timer_init :: () {
    #if OS == .WINDOWS {
        windows_timer_init();
    }
}

wait_for_condition_proc :: #type () -> bool;

wait_for_condition :: ($condition: Code, sleep_interval_ms := 0.1) #expand {
    while !(#insert condition) {
        do_sleep(sleep_interval_ms);
    }
}

// TODO: others?
#if OS == .WINDOWS {
    CreateWaitableTimerExW :: (
        lpTimerAttributes: *SECURITY_ATTRIBUTES,
        lpTimerName:       LPCWSTR,
        dwFlags:           DWORD,
        dwDesiredAccess:   DWORD
    ) -> HANDLE #foreign kernel32;
    kernel32 :: #system_library "kernel32";

    CREATE_WAITABLE_TIMER_HIGH_RESOLUTION :: 0x00000002;
    TIMER_ALL_ACCESS :: 0x1F0003;
    high_resolution_timer: HANDLE;

    windows_timer_init :: () {
        // TODO: this should be elsewhere
        SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_HIGHEST);
        // TODO: what is this?
        SetProcessDPIAware();
        // TODO: does this help high res timer resolution? does it help with thread switching?
        timeBeginPeriod(1);
        high_resolution_timer = CreateWaitableTimerExW(
            null, null, CREATE_WAITABLE_TIMER_HIGH_RESOLUTION, TIMER_ALL_ACCESS
        );
    }

    // TODO: this I THINK accrues error quite quickly and will get out of sync with the cpu clock. 
    // moreover, the higher the frame rate, the less accurate we are telling time. So, there needs to be a 
    // mechanic to re-sync with the cpu occasionally...?
    windows_sleep_milliseconds :: (ms: float64, time_sensitive: bool) {
        MIN_RESOLUTION_MS :: 0.01;
        start_time := get_current_time();
        ms = max(ms, MIN_RESOLUTION_MS);
        high_res_wait_time_seconds := (ms - HACKY_HIGH_RES_TIMER_RESOLUTION_MS) * (1.0 / 1000.0);

        // use the high resolution clock to wait for as long as we can before oversleeping
        while time_since(start_time) < high_res_wait_time_seconds {
            ONE_HUNDRED_MICROSECONDS : s64 : 1000; // in hundreds of nanoseconds
            due_time: LARGE_INTEGER;
            // positive = absolute time, negative = relative time
            // on the test machine, I could only get this to sleep for a minimum of ~.56 ms; I use 100 us
            // as a way to indicate that I want to sleep for the actual minimum sleep resolution. (trying
            // to sleep for a larger amount of time like 0.5 ms seems to increase the inaccuracy)
            due_time.QuadPart = -ONE_HUNDRED_MICROSECONDS;
            // timer can be made periodic (3rd param)
            // timer can call a procedure (4th param)
            set_ok := SetWaitableTimer(high_resolution_timer, *due_time, 0, null, null, 0);
            // assert(set_ok != 0, "%", GetLastError());
            WaitForSingleObject(high_resolution_timer, INFINITE);
        }

        if time_sensitive {
            // burn the clock until we're synced. 
            // *on the test machine* the measured accuracy was in microseconds, which doesn't seem to be using 
            // significantly more cycles right now... that being said, as I understand it, Sleep(0) just waits
            // until the next thread frame which might just mean the thread scheduling is doing some annoyingly
            // slow shit right now and it WILL ?? be really bad for performance bleh.
            CALCULATION_COMPENSATION_MS :: 0.0005;
            wait_time_s := (ms - CALCULATION_COMPENSATION_MS) * (1.0 / 1000.0);
            while time_since(start_time) < wait_time_s {
                sleep_milliseconds(0);
            }
        }
    }
}

os_load_user_proc :: (lib: *Library_Info, name: string) -> *void {
    // for lib.symbol_names {
        // if it == name {
            // return true;
        // }
    // }
    c_name := temp_c_string(name);
    #if OS == .WINDOWS {
        proc := GetProcAddress(lib.handle, c_name);
    } else #if OS == .LINUX || OS == .MACOS {
        proc := dlsym(lib.handle, c_name);
    }
    return proc;
}

MAX_ENTITY_COUNT :: 32767;

Curry :: struct {
    // game runtime variables
    window: *SDL_Window;
    gl_context: SDL_GLContext;
    render_thread: *CurryThread;
    window_settings: WindowSettings;
    frame_count: s64;
    frame_start_time: u64;
    delta_time: float32;
    render_synced_delta_time: float32;
    frame_time_target : float64 = 1.0 / 240.0;
    // burns cycles at the end of each frame to ensure we're syncing each frame with high accuracy
    high_accuracy_frame_time_targeting := true;
    quit: bool;
    #if USING_IMGUI gui_data: GuiData;
    game_thread_id: s32;
    render_thread_id: s32;

    project_directory: string;
    asset_directory: string;

    window_name: string;
    delta_time_init := 0.0;
    delta_time_min := 0.0;
    delta_time_max := 0.25;
    render_in_separate_thread := false;
    render_thread_initialized: u8;
    auto_end := true;
    init_game_proc: UserProc;
    init_render_thread_proc: UserProc;
    post_input_proc: UserProc;
    init_render_proc: UserProc;
    render_proc: UserProc;
    end_frame_proc: UserProc;
    game_loop_end_proc: UserProc;
    render_thread_end_proc: UserProc;

    viewport_hierarchy: []Viewport;
    viewport_hierarchy_buffer: [MAX_VIEWPORT_DEPTH]Viewport;
    viewport_rects: [..]ViewportRect;
    cached_window_width_for_viewports: s32;
    cached_window_height_for_viewports: s32;

    queued_screenspace_lines : [MAX_VIEWPORT_RECT_COUNT][..]ScreenspaceLine;
    primitive_shader : Shader;
    primitive_vertex_array : VertexArray;
    primitive_vertex_buffer : VertexBuffer;
    primitive_index_buffer : IndexBuffer;
    primitive_vertex_count : u64;
    primitive_index_count : u64;
    primitive_draw_mutex: Mutex;

    // TODO: should be a pool of textures. each thing can have its own sprite...................?
    sprites: DynamicPool(Sprite);

    entity_data: *EntityDataPack;
}



create_curry :: (window_name : string = DEFAULT_WINDOW_NAME) -> Curry {
    curry: Curry;
    load_struct_from_text_file(WINDOW_SETTINGS_FILE_PATH, *curry.window_settings);
    curry.window_name = copy_string(window_name);

    SDL_Init(SDL_INIT_VIDEO);

    // TODO: this here is an OpenGL flag...
    curry.window = SDL_CreateWindow(
        temp_c_string(window_name),
        curry.window_settings.position_x,
        curry.window_settings.position_y,
        curry.window_settings.width,
        curry.window_settings.height,
        SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE
    );
    if curry.window == null {
        log("could not create sdl/opengl window: %", to_string(SDL_GetError()));
        exit(1);
    }

    #if USING_IMGUI then curry.gui_data.imgui_context = ImGui.CreateContext();

    return curry;
}
