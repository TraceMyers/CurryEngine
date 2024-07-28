#module_parameters(
    USE_GRAPHICS_API := "opengl",
    GRAPHICS_API_DEBUG := false,
    INCLUDE_IMGUI := false,
    USE_EDITOR := false,
    USE_ENTITIES := true
);

USING_IMGUI :: INCLUDE_IMGUI || USE_EDITOR;

#add_context curry : *Curry = null;

init_game :: (in_curry: *Curry) {
    context.curry = in_curry;
    init_run();
}

run_game :: () {
    defer deinit_run();
    game_loop();
}

game_loop :: () {
    using context.curry;
    if render_in_separate_thread then wait_for_fence(.{*render_thread_initialized, false});
    delta_time = delta_time_init;
    run_user_proc(init_game_proc);

    while !quit {
        cache_window_data();

        // --- input ---
        update_input();
        run_user_proc(post_input_proc);

        // --- render ---
        if render_in_separate_thread {
            wait_for_fence(.{fence=*render_thread.work_done});
            init_render_on_game_thread();
            signal_fence(*render_thread.work_start);
        } else {
            init_render_on_game_thread();
            do_rendering();
        }

        // --- end frame ---
        end_of_frame_update();
    }
}

init_render_on_game_thread :: () {
    using context.curry;
    render_synced_delta_time = delta_time;
    imgui_new_frame();
    #if USE_EDITOR editor_init_render();
    run_user_proc(init_render_proc);
}

end_of_frame_update :: () {
    using context.curry;
    run_user_proc(end_frame_proc);
    reset_temporary_storage();

    ONE_HUNDREDTH_MS_IN_SECONDS :: 0.01 / 1000.0;
    LOW_RES_MS_IN_SECONDS :: (HACKY_HIGH_RES_TIMER_RESOLUTION_MS + 0.1) / 1000.0;
    min_time_to_sync : float64 = ifx high_accuracy_frame_time_targeting 
        then ONE_HUNDREDTH_MS_IN_SECONDS 
        else LOW_RES_MS_IN_SECONDS;
    sync_time := frame_time_target - time_since(frame_start_time);
    if sync_time >= min_time_to_sync {
        do_sleep(sync_time * cast(float64) 1000.0, high_accuracy_frame_time_targeting);
    }

    delta_time = clamp(cast(float32) time_since(frame_start_time), delta_time_min, delta_time_max);
    frame_start_time = get_current_time();
    frame_count += 1;
}

render_loop :: (thread: *Thread) -> s64 {
    rt := cast(*CurryThread) thread;

    #if OS == .WINDOWS then SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_HIGHEST);

    context.curry = rt.curry_instance;
    using context.curry;
    render_thread_id = xx context.thread_index;
    create_graphics_context();

    init_primitive_draws();
    init_viewports();
    sprites_init();
    imgui_init();
    defer deinit_primitive_draws();
    defer sprites_deinit();
    defer imgui_deinit();

    run_user_proc(init_render_thread_proc);
    signal_fence(*render_thread_initialized);

    while !render_thread.should_quit {
        wait_for_any_fence(.{xx *rt.should_quit, false}, .{fence=*rt.work_start});
        do_rendering();
        reset_temporary_storage();
        signal_fence(*render_thread.work_done);
    }

    run_user_proc(render_thread_end_proc);
    #if USE_EDITOR editor_cleanup();
    return 0;
}

do_rendering :: () {
    using context.curry;
    reset_viewports();
    clear_canvas(*window_settings.clear_color);
    #if USE_EDITOR editor_render();
    run_user_proc(render_proc);
    dispatch_primitive_screenspace_draws();
    imgui_render();
    advance_graphics_frame();
}

init_run :: () {
    using context.curry;
    timer_init();
    frame_start_time = get_current_time();
    game_thread_id = xx context.thread_index;
    dynamic_pool_init(*sprites);

    if render_in_separate_thread {
        render_thread = create_thread();
        thread_init(xx render_thread, render_loop);
        thread_start(xx render_thread);
    } else {
        create_graphics_context();
        init_primitive_draws();
        init_viewports();
        sprites_init();
        imgui_init();
        render_thread_id = -1;
    }

    #if USE_ENTITIES {
        entity_data = New(EntityDataPack);
        static_pool_init(*entity_data.entities);
    }
}

deinit_run :: () {
    using context.curry;

    if render_thread then delete_thread(render_thread);
    run_user_proc(game_loop_end_proc);

    if !render_in_separate_thread {
        deinit_primitive_draws();
        sprites_deinit();
        imgui_deinit();
        #if USE_EDITOR editor_cleanup();
    }

    #if USE_ENTITIES {
        array_free(entity_data.pending_entity_collisions);
        free(entity_data);
    }

    dynamic_pool_deinit(*sprites);

    if auto_end {
        delete_curry();
        <<context.curry = .{};
    }
}

#import "Basic";
#import "Math";
#import "SDL";
#import "stb_image";
#import "stb_image_write";
#import "File";
#import "Thread";
#import "Atomics";
#import "xxHash";
#import "IntroSort";
#import "Bindings_Generator";
#import "System";
#import "File_Utilities";
String :: #import "String";

#if USE_EDITOR {
    #load "modules/CurryEditor/module.jai";
}

#load "imgui_impl.jai";
#load "pixel.jai";
#load "entity.jai";
#load "camera.jai";
#load "render_types.jai";
#load "image.jai";
#load "fundamental.jai";
#load "struct_utilities.jai";
#load "threading.jai";
#load "input.jai";
#load "window_view.jai";
#load "primitive_draw.jai";
#load "math.jai";
#load "sprite.jai";
#load "data_structures.jai";
#load "primitive_types.jai";
#load "file.jai";
#load "collision.jai";
#load "asset_management.jai";
#if #run String.compare(USE_GRAPHICS_API, "opengl") == 0 {
    #load "opengl.jai";
} else {
    // no other APIs supported
    #run assert(false);
}

#if OS == .WINDOWS {
    #import "Windows";
} else {
    // ...?
}

