
// TODO: each instance gets its own set of primitive draw arrays, since viewport is determineed from the instance
// TODO: shouldn't be inlining glsl in non-opengl files, different langauges per api and all

ScreenspaceLine :: struct {
    start: Vector2;
    end: Vector2;
    color: Color4b;
    width: float32;
    layer: ScreenspaceLayer;
}

PrimitiveVertexType :: Vertex(3, .COLOR_4B);

// TODO: buffer backing array like w/ window_view
queued_screenspace_lines : [MAX_VIEWPORT_RECT_COUNT][..]ScreenspaceLine;

primitive_shader : Shader;
primitive_vertex_array : VertexArray;
primitive_vertex_buffer : VertexBuffer;
primitive_index_buffer : IndexBuffer;
primitive_vertex_count : u64;
primitive_index_count : u64;
primitive_draw_mutex: Mutex;

MAX_PRIMITIVE_DRAW_VERTICES :: 50000;
MAX_PRIMITIVE_DRAW_INDICES :: MAX_PRIMITIVE_DRAW_VERTICES * 3;
NO_VIEWPORT :: 0;

init_primitive_draws :: () {
    primitive_shader = shader_create_vf(primitive_tri_vert, primitive_tri_frag);
    assert(!shader_invalid(*primitive_shader));
    primitive_vertex_array = vertex_array_create();
    primitive_vertex_buffer = vertex_buffer_create(PrimitiveVertexType, MAX_PRIMITIVE_DRAW_VERTICES, GL_DYNAMIC_DRAW);
    primitive_index_buffer = index_buffer_create(u16, MAX_PRIMITIVE_DRAW_INDICES, GL_DYNAMIC_DRAW);
    vertex_array_add_buffer(*primitive_vertex_array, *primitive_vertex_buffer, PrimitiveVertexType);
    for i : 0..queued_screenspace_lines.count-1 {
        queued_screenspace_lines[i].allocator = temp;
    }
    init(*primitive_draw_mutex, "Primitive Draws");
}

deinit_primitive_draws :: () {
    vertex_array_delete(*primitive_vertex_array);
    vertex_buffer_delete(*primitive_vertex_buffer);
    index_buffer_delete(*primitive_index_buffer);
    shader_delete(*primitive_shader);
    primitive_vertex_count = 0;
    primitive_index_count = 0;
    for i : 0..queued_screenspace_lines.count-1 {
        queued_screenspace_lines[i].data = null;
        queued_screenspace_lines[i].count = 0;
    }
}

draw_screenspace_line :: (
    start: Vector2, 
    end: Vector2, 
    color: Color4b, 
    width: float32, 
    layer: ScreenspaceLayer = ._0,
    viewport: s32 = -1
) -> bool {
    lock(*primitive_draw_mutex);
    defer unlock(*primitive_draw_mutex);

    new_vertex_count := primitive_vertex_count + 4;
    new_index_count := primitive_index_count + 6;
    if new_vertex_count > MAX_PRIMITIVE_DRAW_VERTICES || new_index_count > MAX_PRIMITIVE_DRAW_INDICES then return false;
    if viewport == -1 then viewport = cast(s32) viewport_rects.count - 1;
    array_add(*queued_screenspace_lines[viewport], .{start, end, color, width, layer});
    primitive_vertex_count = new_vertex_count;
    primitive_index_count = new_index_count;
    return true;
}

// start and end are any two points. the box that is drawn will be the smallest box that contains the two points.
draw_screenspace_box :: (
    start: Vector2, 
    end: Vector2, 
    color: Color4b, 
    line_width: float32, 
    layer: ScreenspaceLayer = ._0, 
    do_fill := false,
    viewport: s32 = -1
) -> bool {
    success := true;
    if do_fill {
        half_line_width := line_width * 0.5;
        min_pos := Vector2.{min(start.x, end.x), min(start.y, end.y)} - Vector2.{half_line_width, half_line_width};
        max_pos := Vector2.{max(start.x, end.x), max(start.y, end.y)} + Vector2.{half_line_width, half_line_width};
        bot := Vector2.{(min_pos.x + max_pos.x) * 0.5, min_pos.y};
        top := Vector2.{(min_pos.x + max_pos.x) * 0.5, max_pos.y};
        success = draw_screenspace_line(bot, top, color, max_pos.x - min_pos.x, layer, viewport);
    } else {
        assert(line_width > 0.0);
        half_lw := line_width * 0.5;
        box_ll := Vector2.{min(start.x, end.x), min(start.y, end.y)};
        box_ul := Vector2.{min(start.x, end.x), max(start.y, end.y)};
        box_ur := Vector2.{max(start.x, end.x), max(start.y, end.y)};
        box_lr := Vector2.{max(start.x, end.x), min(start.y, end.y)};
        // making it so the line corners don't overlap
        success = draw_screenspace_line(
            box_ll + Vector2.{0.0, -half_lw}, box_ul + Vector2.{0.0, half_lw}, color, line_width, layer, viewport
        );
        success = draw_screenspace_line(
            box_ul + Vector2.{half_lw, 0.0}, box_ur + Vector2.{-half_lw, 0.0}, color, line_width, layer, viewport
        );
        success = draw_screenspace_line(
            box_ur + Vector2.{0.0, half_lw}, box_lr + Vector2.{0.0, -half_lw}, color, line_width, layer, viewport
        );
        success = draw_screenspace_line(
            box_lr + Vector2.{-half_lw, 0.0}, box_ll + Vector2.{half_lw, 0.0} , color, line_width, layer, viewport
        );
    }
    return success;
}

dispatch_primitive_screenspace_draws :: () {
    lock(*primitive_draw_mutex);
    defer unlock(*primitive_draw_mutex);

    indices := [..]u16.{allocator = temp};
    vertices := [..]PrimitiveVertexType.{allocator = temp};
    screenspace_camera := camera_create(.ORTHOGRAPHIC, ._2D, ViewSettingsOrthographic.{use_screenspace=true});

    for v : 0..MAX_VIEWPORT_RECT_COUNT-1 {
        draw_request_count := queued_screenspace_lines[v].count;
        if draw_request_count == 0 then continue;

        array_reserve(*vertices, draw_request_count * 4);
        array_reserve(*indices, draw_request_count * 6);

        i : u16 = 0;
        for queued_screenspace_lines[v] {
            half_width := it.width * 0.5;

            start := Vector3.{it.start.x, it.start.y, 0.0};
            end := Vector3.{it.end.x, it.end.y, 0.0};

            to_end := normalize(end - start) * half_width;
            to_start := -to_end;
            z := screenspace_layer_middle(it.layer);
            ortho_ccw := Vector3.{-to_end.y, to_end.x, z}; // 'up' if end is to the right of start
            ortho_cw := Vector3.{to_end.y, -to_end.x, z}; // 'down' if end to the right of start
            
            array_add(*vertices, .{start + ortho_cw,  it.color});
            array_add(*vertices, .{end   + ortho_cw,  it.color});
            array_add(*vertices, .{start + ortho_ccw, it.color});
            array_add(*vertices, .{end   + ortho_ccw, it.color});

            array_add(*indices, i);
            array_add(*indices, i+1);
            array_add(*indices, i+2);
            array_add(*indices, i+3);
            array_add(*indices, i+2);
            array_add(*indices, i+1);

            i += 4;
        }
        array_reset(*queued_screenspace_lines[v]);

        set_viewport_for_draw(v);
        screenspace_view_projection := viewport_view_projection_matrix(screenspace_camera, viewport_rects[v]);

        shader_bind(*primitive_shader);
        shader_set_uniform(*primitive_shader, "u_MVP", screenspace_view_projection);

        vertex_buffer_bind(*primitive_vertex_buffer);
        index_buffer_bind(*primitive_index_buffer);

        // TODO: un-opengl this
        gl_assert(glBufferSubData(GL_ARRAY_BUFFER, 0, vertices.count * size_of(PrimitiveVertexType), *vertices[0]));
        gl_assert(glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, indices.count * size_of(u16), *indices[0]));
        
        draw(*primitive_vertex_array, *primitive_index_buffer, *primitive_shader, GL_TRIANGLES, 0, indices.count);

        array_reset(*vertices);
        array_reset(*indices);
    }

    primitive_vertex_count = 0;
    primitive_index_count = 0;
}


primitive_tri_vert := #string END
    #version 330

    layout(location=0) in vec3 position;
    layout(location=1) in vec4 v_color;

    uniform mat4 u_MVP;

    out vec4 f_color;

    void main() {
        gl_Position = u_MVP * vec4(position, 1.0);
        f_color = v_color;
    }
END

primitive_tri_frag := #string END
    #version 330

    layout(location=0) out vec4 color;

    in vec4 f_color;

    void main() {
        color = f_color;
    }
END

