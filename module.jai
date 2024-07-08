#module_parameters(
    USE_GRAPHICS_API := "opengl",
    GRAPHICS_API_DEBUG := false,
    INCLUDE_IMGUI := false
);

instance_count: s32;

run_game :: (curry: *Curry) {
    init_run(curry);
    defer deinit_run(curry);
    game_loop(curry);
}

game_loop :: (using curry: *Curry) {
    if render_in_separate_thread then wait_for_fence(.{*curry.render_thread_initialized, false});
    delta_time = delta_time_init;
    run_user_proc(init_game_thread_proc, curry);

    while !quit {
        cache_window_data(curry);

        // --- input ---
        run_user_proc(pre_input_proc, curry);
        update_input(curry);

        // --- pre render ---
        run_user_proc(pre_render_proc, curry);

        // --- render ---
        if render_in_separate_thread {
            wait_for_fence(.{fence=*render_thread.work_done});
            render_synced_delta_time = delta_time;
            imgui_new_frame(curry);
            run_user_proc(init_render_proc, curry);
            signal_fence(*render_thread.work_start);
        } else {
            imgui_new_frame(curry);
            run_user_proc(init_render_proc, curry);
            do_rendering(curry);
        }

        // --- end frame ---
        run_user_proc(end_frame_proc, curry);
        end_of_frame_update(curry);
    }
}

end_of_frame_update :: (using curry: *Curry) {
    reset_temporary_storage();

    ONE_HUNDREDTH_MS :: 0.00001;
    min_time_to_sync : float64 = ifx high_accuracy_frame_time_targeting 
        then  ONE_HUNDREDTH_MS
        else (HACKY_HIGH_RES_TIMER_RESOLUTION_MS + 0.1) / 1000.0;
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
    using rt.curry_instance;

    #if OS == .WINDOWS then SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_HIGHEST);

    render_thread_id = xx context.thread_index;
    create_graphics_context(rt.curry_instance);

    init_primitive_draws();
    init_viewports();
    sprites_init();
    imgui_init(rt.curry_instance);
    defer deinit_primitive_draws();
    defer sprites_deinit();
    defer imgui_deinit(rt.curry_instance);

    run_user_proc(init_render_thread_proc, rt.curry_instance);

    signal_fence(*render_thread_initialized);

    while !render_thread.should_quit {
        wait_for_any_fence(.{xx *rt.should_quit, false}, .{fence=*rt.work_start});
        do_rendering(rt.curry_instance);
        reset_temporary_storage();
        signal_fence(*render_thread.work_done);
    }
    return 0;
}

do_rendering :: (using curry: *Curry) {
    reset_viewports(curry);
    clear_canvas(*window_settings.clear_color);

    if xx context.thread_index == game_thread_id {
        run_user_proc(render_in_game_thread_proc, curry);
    } else if xx context.thread_index == render_thread_id {
        run_user_proc(render_in_render_thread_proc, curry);
    } else assert(false);

    dispatch_primitive_screenspace_draws();
    imgui_render(curry);
    advance_graphics_frame(curry);
}

init_run :: (using curry: *Curry) {
    instance_count += 1;
    timer_init();
    frame_start_time = get_current_time();
    game_thread_id = xx context.thread_index;
    if render_in_separate_thread {
        render_thread = create_thread(curry);
        thread_init(xx render_thread, render_loop);
        thread_start(xx render_thread);
    } else {
        create_graphics_context(curry);
        init_primitive_draws();
        init_viewports();
        sprites_init();
        imgui_init(curry);
        render_thread_id = -1;
    }
}

deinit_run :: (using curry: *Curry) {
    instance_count -= 1;
    if render_thread then delete_thread(render_thread);
    if !render_in_separate_thread {
        deinit_primitive_draws();
        sprites_deinit();
        imgui_deinit(curry);
    }
    if curry.auto_end then delete_curry(curry);
    <<curry = .{};
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
String :: #import "String";

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

