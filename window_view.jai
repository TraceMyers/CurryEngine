
ViewportOffsetType :: enum u32 { 
    PROPORTION; 
    PIXEL_COUNT;
}

ViewportOffset :: struct {
    type := ViewportOffsetType.PROPORTION;
    proportion: float32;

#place proportion;
    pixel_count: s32 = ---;
}

Viewport :: struct {
    LEFT :: 0;
    BOTTOM :: 1;
    RIGHT :: 2;
    TOP :: 3;
    offset_left: ViewportOffset;
    offset_bottom: ViewportOffset;
    offset_right: ViewportOffset;
    offset_top: ViewportOffset;
    locked := false;

#place offset_left;
    offsets: [4]ViewportOffset = ---;
}

// TODO: could use u16 int vectors to make this 8 bytes
ViewportRect :: struct {
    bottom_left: IntVector2;
    dimensions: IntVector2;
}

MAX_VIEWPORT_DEPTH :: 128;
MAX_VIEWPORT_RECT_COUNT :: 512;
viewport_hierarchy: []Viewport;
viewport_hierarchy_buffer: [MAX_VIEWPORT_DEPTH]Viewport;
viewport_rects: [..]ViewportRect;
cached_window_width_for_viewports: s32;
cached_window_height_for_viewports: s32;

init_viewports :: () {
    viewport_hierarchy.data = *viewport_hierarchy_buffer[0];
    viewport_rects.allocator = temp;
}

push_viewport :: (v := Viewport.{}, do_cache := false) -> s32 {
    index := viewport_hierarchy.count;
    assert(viewport_hierarchy.count < MAX_VIEWPORT_DEPTH);
    viewport_hierarchy.count += 1;
    viewport_hierarchy[index] = v;
    if do_cache then cache_viewport_rect();
    return xx index;
}

pop_viewport :: () {
    pop_index := viewport_hierarchy.count - 1;
    assert(!viewport_hierarchy[pop_index].locked);
    viewport_hierarchy.count -=1;
}

reset_viewports :: (push_window_viewport := true) {
    viewport_hierarchy.count = 0;
    for *v: viewport_hierarchy_buffer {
        <<v = .{};
    }
    array_reset(*viewport_rects);

    cached_window_width_for_viewports = context.curry.window_settings.width;
    cached_window_height_for_viewports = context.curry.window_settings.height;

    if push_window_viewport {
        push_viewport();
        cache_viewport_rect();
    }
}

cache_viewport_rect :: () -> s32 {
    assert(viewport_rects.count < MAX_VIEWPORT_RECT_COUNT);
    remain_width := cached_window_width_for_viewports;
    remain_height := cached_window_height_for_viewports;
    rect: ViewportRect;
    rect.bottom_left = .{0, 0};
    rect.dimensions = .{remain_width, remain_height};
    for i : 0..viewport_hierarchy.count-1 {
        viewport_offsets :=  viewport_hierarchy[i].offsets;
        pixel_offsets: [4]s32 = ---;
        respective_dimensions := s32.[remain_width, remain_height, remain_width, remain_height];
        for j : 0..3 {
            pixel_offsets[j] = ifx viewport_offsets[j].type == .PROPORTION 
                then xx (viewport_offsets[j].proportion * xx respective_dimensions[j])
                else viewport_offsets[j].pixel_count;
        }
        width_boundary := rect.bottom_left.x + rect.dimensions.x;
        height_boundary := rect.bottom_left.y + rect.dimensions.y;
        rect.bottom_left.x = min(rect.bottom_left.x + pixel_offsets[Viewport.LEFT], width_boundary);
        rect.bottom_left.y = min(rect.bottom_left.y + pixel_offsets[Viewport.BOTTOM], height_boundary);
        remain_width = max(remain_width - pixel_offsets[Viewport.LEFT] - pixel_offsets[Viewport.RIGHT], 0);
        remain_height = max(remain_height - pixel_offsets[Viewport.BOTTOM] - pixel_offsets[Viewport.TOP], 0);
        rect.dimensions.x = remain_width;
        rect.dimensions.y = remain_height;
    }
    array_add(*viewport_rects, rect);
    return xx (viewport_rects.count - 1);
}

last_cached_viewport :: inline () -> s64 {
    assert(viewport_rects.count > 0);
    return viewport_rects.count - 1;
}

last_cached_viewport_rect :: inline () -> ViewportRect {
    return viewport_rects[last_cached_viewport()];
}

highlight_last_cached_viewport :: (
    outline_thickness := 4.0, 
    outline_color := Color4b.{rgb=COLOR3B_WHITE, a=100}, 
    fill_color := Color4b.{rgb=COLOR3B_YELLOW, a=25}
) {
    viewport_rect := last_cached_viewport_rect();
    if fill_color.a > 0 {
        draw_screenspace_box(
            .{0.0, 0.0},
            .{xx viewport_rect.dimensions.x, xx viewport_rect.dimensions.y},
            fill_color,
            0.0,
            ._63,
            true
        );
    }
    if outline_color.a > 0 {
        draw_screenspace_box(
            .{0.0, 0.0},
            .{xx viewport_rect.dimensions.x, xx viewport_rect.dimensions.y},
            outline_color,
            outline_thickness,
            ._63
        );
    }
}

draw_line_across_viewport_bottom :: () {
    rect := last_cached_viewport_rect();
    color := COLOR4B_WHITE;
    color.a = 128;
    draw_screenspace_line(.{0.0, 0.0}, .{xx rect.dimensions.x, 0.0}, color, 2.0);
}

draw_line_across_viewport_top :: () {
    rect := last_cached_viewport_rect();
    color := COLOR4B_WHITE;
    color.a = 128;
    draw_screenspace_line(.{0.0, xx rect.dimensions.y}, .{xx rect.dimensions.x, xx rect.dimensions.y}, color, 2.0);
}

draw_line_across_viewport_left :: () {
    rect := last_cached_viewport_rect();
    color := COLOR4B_WHITE;
    color.a = 128;
    draw_screenspace_line(.{0.0, 0.0}, .{0.0, xx rect.dimensions.y}, color, 2.0);
}

draw_line_across_viewport_right :: () {
    rect := last_cached_viewport_rect();
    color := COLOR4B_WHITE;
    color.a = 128;
    draw_screenspace_line(.{xx rect.dimensions.x, 0.0}, .{xx rect.dimensions.x, xx rect.dimensions.y}, color, 2.0);
}

