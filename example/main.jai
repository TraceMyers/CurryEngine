#import "CurryEngine"(
    USE_GRAPHICS_API="opengl", 
    GRAPHICS_API_DEBUG=true,
    INCLUDE_IMGUI=true
);
#import "Basic";
#import "GL";
#import "Math";

MIN_LEFT_BAR_WIDTH : s32 = 15;
left_bar_width := 500;
camera : Camera;
tex_checker: Texture;
sprite_checker: Sprite;
camera_origin_y : float;
on_ground := true;
camera_velocity_y := 0.0;
sprite_quat: Quaternion;

main :: () {
    curry := create_curry();
    using curry;

    // --- runtime parameterization ---
    render_in_separate_thread = true;
    delta_time_init = 1.0 / 120.0;

    // --- set the functions that will be called during the game loop ---
    init_game_thread_proc = initialize_game_thread;
    init_render_thread_proc = initialize_render_thread;
    pre_input_proc = pre_input;
    pre_render_proc = pre_render;
    init_render_proc = init_render;
    render_in_game_thread_proc = render;
    render_in_render_thread_proc = render;
    end_frame_proc = end_frame;

    run_game(*curry);
}

initialize_render_thread :: (curry: *Curry, dt: float32) {
    tex_checker = texture_create("checker.png", .{filter_minification=GL_NEAREST, filter_magnification=GL_NEAREST});
    sprite_checker = sprite_create(*tex_checker); 
    sprite_checker.scale = 1.0;
    camera = camera_create(.PERSPECTIVE, ._2D, ViewSettingsPerspective.{});
    camera.perspective_settings.vertical_fov_degrees = 80;
    camera_origin_y = camera.y;
}

initialize_game_thread :: (curry: *Curry, dt: float32) {

}

pre_input :: (curry: *Curry, dt: float32) { 

}

pre_render :: (curry: *Curry, dt: float32) { 
    CAM_SPEED :: 25.0;
    if key_down(#char "w") then camera.z -= CAM_SPEED * dt;
    if key_down(#char "s") then camera.z += CAM_SPEED * dt;
    if key_down(#char "d") then camera.x += CAM_SPEED * dt;
    if key_down(#char "a") then camera.x -= CAM_SPEED * dt;
    if key_just_pressed(#char "j") && on_ground {
        on_ground = false;
        camera_velocity_y = 60.0;
    }

    camera_velocity_y -= 98.0 * dt;
    camera.y += camera_velocity_y * dt;

    if camera.y < camera_origin_y {
        on_ground = true;
        camera.y = camera_origin_y;
        camera_velocity_y = 0.0;
    }
}

init_render :: (curry: *Curry, dt: float32) {

}

render :: (using curry: *Curry, dt: float32) { 
    top_bar_height: s32;
    if (ImGui.BeginMainMenuBar()) {
        if (ImGui.BeginMenu("Menu")) {
            ImGui.MenuItem("it's a menu I guess", "CTRL+Z");
            ImGui.EndMenu();
        }
        top_bar_height = xx ImGui.GetFrameHeight();
        ImGui.EndMainMenuBar();
    }

    left_bar_width = clamp(left_bar_width, MIN_LEFT_BAR_WIDTH, window_settings.width - MIN_LEFT_BAR_WIDTH);
    left_bar_height := window_settings.height - top_bar_height;

    ImGui.SetNextWindowSize(.{xx left_bar_width, xx left_bar_height});
    ImGui.SetNextWindowPos(.{0.0, xx top_bar_height});

    LEFT_BAR_FLAGS : ImGui.WindowFlags : .NoTitleBar | .NoMove | .NoResize;
    if (ImGui.Begin("Left Side Bar", null, xx LEFT_BAR_FLAGS)) {
        ImGui.ColorEdit3("clear color", xx *curry.window_settings.clear_color.r);
        ImGui.End();
    }

    // game viewport
    push_viewport(.{
        offset_left.type = .PIXEL_COUNT,
        offset_left.pixel_count = xx left_bar_width,
        offset_top.type = .PIXEL_COUNT,
        offset_top.pixel_count = xx top_bar_height
    });

    // left view
    push_viewport(.{offset_right.proportion=0.5});
    cache_viewport_rect(curry);
    viewport_rect := last_cached_viewport_rect();
    draw_screenspace_line(.{-10.0, 0.0}, .{490.0, 1000.0}, COLOR4B_SKY, 20.0, ._2);
    draw_screenspace_line(.{-20.0, 0.0}, .{480.0, 1000.0}, COLOR4B_SALMON, 20.0, ._3);
    draw_screenspace_line(.{0.0, 0.0}, .{500.0, 1000.0}, COLOR4B_SEA, 20.0, ._1);
    draw_screenspace_box(
        .{0.0, 0.0},
        .{xx curry.window_settings.width, xx curry.window_settings.height},
        .{192, 10, 10, 30},
        0.0,
        ._4,
        true
    );
    draw_screenspace_box(
        .{0.0, 0.0},
        .{xx viewport_rect.dimensions.x, xx viewport_rect.dimensions.y},
        .{200, 200, 200, 255},
        4.0,
        ._10
    );
    pop_viewport();
    

    // right view
    push_viewport(.{offset_left.proportion=0.5});

    // bottom right
    push_viewport(.{offset_top.proportion=0.5});
    cache_viewport_rect(curry);
    viewport_rect = last_cached_viewport_rect();
    draw_screenspace_line(.{-10.0, 0.0}, .{490.0, 1000.0}, COLOR4B_SKY, 20.0, ._1);
    draw_screenspace_line(.{-20.0, 0.0}, .{480.0, 1000.0}, COLOR4B_SALMON, 20.0, ._2);
    draw_screenspace_line(.{0.0, 0.0}, .{500.0, 1000.0}, COLOR4B_SEA, 20.0, ._0);
    draw_screenspace_box(
        .{0.0, 0.0},
        .{xx curry.window_settings.width, xx curry.window_settings.height},
        .{10, 192, 10, 30},
        0.0,
        ._4,
        true
    );
    draw_screenspace_box(
        .{0.0, 0.0},
        .{xx viewport_rect.dimensions.x, xx viewport_rect.dimensions.y},
        .{200, 200, 200, 255},
        4.0,
        ._10
    );
    pop_viewport();

    // top right
    push_viewport(.{offset_bottom.proportion=0.5});
    cache_viewport_rect(curry);

    // after camera moves...
    set_viewport_for_draw(last_cached_viewport());
    viewport_rect = last_cached_viewport_rect();
    view_projection := viewport_view_projection_matrix(camera, viewport_rect);

    sprite_location_mat: Matrix4 = ---;
    identity(*sprite_location_mat);
    rotation := cast(float32) seconds_since_init();
    half_rotation := rotation * 0.5;
    axis := Vector3.{0.0, 1.0, 0.0};
    sin_axis := axis * sin(half_rotation);
    sprite_quat.xyz = sin_axis;
    sprite_quat.w = cos(half_rotation);
    sprite_model := rotate(*sprite_location_mat, sprite_quat);
    sprite_mvp := view_projection * sprite_model;

    // draw everything
    sprite_draw(*sprite_checker, .{}, *sprite_mvp);
    // ....

    draw_screenspace_box(
        .{0.0, 0.0},
        .{xx viewport_rect.dimensions.x, xx viewport_rect.dimensions.y},
        .{200, 200, 200, 255},
        4.0,
        ._10
    );

    pop_viewport();
    pop_viewport();
    pop_viewport();
}

end_frame :: (curry: *Curry, dt: float32) { 

}

