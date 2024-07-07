
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

init_viewports :: () {
    viewport_hierarchy.data = *viewport_hierarchy_buffer[0];
    viewport_rects.allocator = temp;
}

push_viewport :: (v := Viewport.{}, do_cache := false) -> s32 {
    index := viewport_hierarchy.count;
    assert(viewport_hierarchy.count < MAX_VIEWPORT_DEPTH);
    viewport_hierarchy.count += 1;
    viewport_hierarchy[index] = v;
    return xx index;
}

pop_viewport :: () {
    pop_index := viewport_hierarchy.count - 1;
    assert(!viewport_hierarchy[pop_index].locked);
    viewport_hierarchy.count -=1;
}

reset_viewports :: (curry: *Curry, push_window_viewport := true) {
    viewport_hierarchy.count = 0;
    for *v: viewport_hierarchy_buffer {
        <<v = .{};
    }
    array_reset(*viewport_rects);

    if push_window_viewport {
        push_viewport();
        cache_viewport_rect(curry);
    }
}

cache_viewport_rect :: (curry: *Curry) -> s32 {
    assert(viewport_rects.count < MAX_VIEWPORT_RECT_COUNT);
    remain_width := curry.window_settings.width;
    remain_height := curry.window_settings.height;
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
