// TODO:
// - sprite hash-lookup pool (purpose: makes for faster iteration time, don't.
// need a locked-down way to address sprite data - can just refer to them all by name);
// - asset name hashing metaprogram: before compilation, recursively iterate over a directory, finds
// all files with a matching extension and generates a file with constants a constant struct per asset:
    // - hash of the file name 
    // - full paths to the file
// example usage:
// k := get_sprite(sprite_asset_struct)
//      ... first, it will attempt to find a sprite with the hash as an ID      
//      ... if that doesn't exist, it will load the sprite at the given path and tag it with the hash as an id
// also, because the IDs are generated from the file names, an id could be generated at runtime using the filename
// for whatever reason.
// though the sprite asset structs are constants, they are treated as runtime data for simplicity's sake. making a
// polymorph per sprite seems dumb, plus probably quite a bit of the time we want to load sprites or whatever without
// knowing which sprite we want.

test_sprite: Sprite;
test_camera : Camera;

main :: () {
    defer log("exited without spice");
    curry := create_curry();

    {
        using curry;
        #if !USING_CURRY_EDITOR {
            window_settings.clear_color = .{xx 0xe2 / 255.0, xx 0x6a / 255.0, xx 0x2c / 255.0};
        }
        render_in_separate_thread = true;
        init_game_proc = init_game;
        init_render_thread_proc = init_render_thread;
        post_input_proc = post_input;
        init_render_proc = init_render;
        render_proc = render;
        end_frame_proc = end_frame;
        game_loop_end_proc = game_loop_end;
        render_thread_end_proc = render_thread_end;
    }

    init_game(*curry);

    run_game();
}

// [game thread]
// called after all engine resources have been initialized, just before the game loop starts.
// if render_in_separate_thread is true, called after init_render_thread()
init_game :: () {
    using context.curry;
}

// [render thread] (only called if render_in_separate_thread is true)
// called after all engine resources have been initialized, just before the render loop starts, and
// before init_game()
init_render_thread :: () {
    using context.curry;

    test_sprite = sprite_load(SPRITE_SCOTT);
    test_camera = camera_create(.PERSPECTIVE, ._3D);
}

// [game thread]
// called after getting input. game thread step 1.
post_input :: () {
    using context.curry;

    if key_down(#char "w") {
        test_camera.position += camera_forward(*test_camera) * 100.0 * delta_time;
    }
    if key_down(#char "s") {
        test_camera.position += -camera_forward(*test_camera) * 100.0 * delta_time;
    }
}

// [game thread]
// called before rendering. game thread step 2.
// if render_in_separate_thread is true, this is called while the render thread isn't working, so it is safe to 
// transfer data between the threads. note that the graphics context lives on the thread where rendering is done,
// so stuff like graphics API data is only available to that thread.
init_render :: () {
    using context.curry;
}

// [render thread OR game thread]  (depends on render_in_separate_thread)
// called after clearing the image with the clear color and before dispatching draws, so this is where all rendering 
// must be done. always called after init_render(). if render_in_separate_thread is true, this function is run in 
// parallel with the game loop; the render thread syncs to the game loop once per frame.
render :: () {
    using context.curry;

    sprite_animate(*test_sprite, delta_time);
    view_projection := viewport_view_projection_matrix(test_camera, last_cached_viewport_rect());
    sprite_draw(*test_sprite, .{}, *view_projection);
}

// [game thread]
// called just before resetting temporary storage and frame time syncing.
end_frame :: () {
    using context.curry;
}

// [game thread]
// called after the game loop has been exited, before engine resource cleanup. if render_in_separate_thread is true, 
// called after render_thread_end() is completed, so graphics resources will have already been cleaned up.
game_loop_end :: () {
    using context.curry;
}

// [render thread]
// called after the render loop has been exited, before graphics resource cleanup.
render_thread_end :: () {
    using context.curry;
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ---------------------------------------------------------------------------------------------------------------------
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

USING_CURRY_EDITOR :: false;

#import "CurryEngine" (
    GRAPHICS_API_DEBUG = true,
    USE_EDITOR = USING_CURRY_EDITOR
);

#import "Basic";
#import "Math";

#load "assets.jai";
