
SpriteSaveData :: struct {
    file_path: string;
    header: SpriteHeader;
    texture_creation_info: TextureCreationInfo;
    use_context: *Context;
}

SpriteHeader :: struct {
    frame_rate: u16 = 12;
    frame_count: u16 = 1;
    scale := 1.0;
    loop :=  true;
}

Sprite :: struct {
    using header: SpriteHeader;
    texture: Texture;
    tint := COLOR4B_WHITE;
    frame_index: s32;
    frame_timer: float32;
    frame_paused: bool;
}

sprite_draw_data: MeshDrawData;

sprites_init :: () {
    VertexType :: Vertex(2, .UV_2F);
    vertices := VertexType.[
        .{.{-0.5, -0.5}, .{0.0, 0.0}},
        .{.{ 0.5, -0.5}, .{1.0, 0.0}},
        .{.{ 0.5,  0.5}, .{1.0, 1.0}},
        .{.{-0.5,  0.5}, .{0.0, 1.0}},
    ];
    indices := u8.[
        0, 1, 2,
        0, 2, 3
    ];

    sprite_draw_data.shader = shader_create_vf(sprite_tri_vert, sprite_tri_frag);
    assert(!shader_invalid(*sprite_draw_data.shader));

    sprite_draw_data.va = vertex_array_create();
    sprite_draw_data.vb = vertex_buffer_create(vertices, GL_STATIC_DRAW);
    sprite_draw_data.ib = index_buffer_create(indices, GL_STATIC_DRAW);
    vertex_array_add_buffer(*sprite_draw_data.va, *sprite_draw_data.vb, VertexType);
}

sprites_deinit :: () {
    shader_delete(*sprite_draw_data.shader);
    vertex_array_delete(*sprite_draw_data.va);
    vertex_buffer_delete(*sprite_draw_data.vb);
    index_buffer_delete(*sprite_draw_data.ib);
}

sprite_save_stbi_callback :: (_context: *void, data: *void, size: s32) -> void #c_call {
    save_data := cast(*SpriteSaveData) _context;
    // it's illegal to call jai procedures in a c_call unless we push a context. all jai procedures require a backing
    // context, but c functions have none.
    push_context <<save_data.use_context {
        f := file_open(save_data.file_path, for_writing=true);
        defer file_close(*f);
        header_string: string = .{size_of(SpriteHeader), xx *save_data.header};
        creation_info_string: string = .{size_of(TextureCreationInfo), xx *save_data.texture_creation_info};
        data_string: string = .{size, xx data};
        file_write(*f, header_string);
        file_write(*f, creation_info_string);
        file_write(*f, data_string);
    }
}

sprite_save :: (using sprite: *Sprite, file_path: string) {
    channels := pixel_channels(texture.pixel_tag);
    row_size := pixel_size(texture.pixel_tag) * texture.width;
    save_data := SpriteSaveData.{file_path, header, texture.creation_info, *context};
    stbi_write_png_to_func(
        sprite_save_stbi_callback, 
        xx *save_data, 
        texture.width, 
        texture.height, 
        xx channels, 
        texture.raw_data.data, 
        xx row_size
    ); 
}

sprite_load :: inline (asset_ref: CurryAssetReference) -> Sprite {
    full_path := tprint("%/%", context.curry.asset_directory, asset_ref.asset_path);
    return sprite_load(full_path);
}

sprite_load :: (file_path: string) -> Sprite {
    stbi_set_flip_vertically_on_load(0);
    defer stbi_set_flip_vertically_on_load(1);
    f := file_open(file_path, keep_existing_content=true);
    defer file_close(*f);
    file_string, read_file_success := read_entire_file(f);
    assert(read_file_success);
    defer free(file_string);

    header: SpriteHeader = ---;
    memcpy(*header, file_string.data, size_of(SpriteHeader));
    file_string = String.slice(file_string, size_of(SpriteHeader), file_string.count - size_of(SpriteHeader));

    creation_info: TextureCreationInfo = ---;
    memcpy(*creation_info, file_string.data, size_of(TextureCreationInfo));
    file_string = String.slice(file_string, size_of(TextureCreationInfo), file_string.count - size_of(TextureCreationInfo));

    width, height, channel_count: s32;
    assert(read_file_success);
    data: *u8 = stbi_load_from_memory(
        file_string.data, 
        xx file_string.count,
        *width,
        *height,
        *channel_count,
        4
    );

    image := image_create(data, width, height, .SPRITE_ANIMATION, .STBI);
    image.asset_path = String.copy_string(file_path);
    tex := texture_create(image, creation_info);
    return sprite_create(*tex, header);
}

sprite_create :: inline (
    file_path: string, header := SpriteHeader.{}, tex_create_info := TextureCreationInfo.{}
) -> Sprite {
    tex := texture_create(file_path, .{});
    return sprite_create(*tex, header);
}

sprite_create :: inline (tex: *Texture, header := SpriteHeader.{}) -> Sprite {
    assert(tex.height % header.frame_count == 0);
    assert(header.frame_count > 0);
    assert(header.frame_rate > 0);
    assert(header.scale > 0.0);
    sprite := Sprite.{
        header = header,
        texture = <<tex
    };
    return sprite;
}

sprite_delete :: (sprite: *Sprite) {
    texture_delete(*sprite.texture);
    <<sprite = .{};
}

sprite_draw :: (using sprite: *Sprite, position: Vector3, view_projection: *Matrix4) {
    assert(frame_count > 0);
    translate_mat := make_translation_matrix4(position);
    inv_frame_ct := 1.0 / xx frame_count;
    scale_mat := Matrix4.{
        _11 = scale * xx texture.width, 
        _22 = scale * xx texture.height * inv_frame_ct, 
        _33 = scale, 
        _44 = 1.0
    };
    mvp := view_projection * (translate_mat * scale_mat);
    draw(sprite, *mvp);
}

sprite_frame_advance :: inline (using sprite: *Sprite, by_frames: s32 = 1) {
    sprite_frame_set(sprite, frame_index + by_frames, false);
}

sprite_frame_set :: inline (using sprite: *Sprite, to_frame: s32, reset_timer := true) {
    frame_index = to_frame;
    frame_index = frame_index % frame_count;
    if reset_timer then frame_timer = 0.0;
}

sprite_animate :: (using sprite: *Sprite, delta_time: float) {
    if frame_paused then return;
    else if frame_index == frame_count - 1 && !loop then return;
    frame_timer += delta_time;
    frame_rate_flt := cast(float32) frame_rate; 
    frame_advance_count := frame_timer * frame_rate_flt;
    if frame_advance_count >= 1.0 {
        frame_timer -= floor(frame_advance_count) / frame_rate_flt;
        sprite_frame_advance(sprite, xx frame_advance_count);
    }
}

// TODO: all sprites just have a z of -1 lol
sprite_tri_vert := #string END
    #version 330

    layout(location=0) in vec2 position;
    layout(location=1) in vec2 uv;

    out vec2 f_uv;

    uniform mat4 u_MVP;

    void main() {
        gl_Position = u_MVP * vec4(position, -0.1, 1.0);
        f_uv = uv;
    }
END

sprite_tri_frag := #string END
    #version 330
    // #extension GL_EXT_gpu_shader4 : enable

    layout(location=0) out vec4 color;

    in vec2 f_uv;

    uniform sampler2D u_texture;
    uniform float u_animYScalar;
    uniform float u_animYOffset;
    uniform int u_tint;

    void main() {
        float y = f_uv.y * u_animYScalar + u_animYOffset;
        float r = float((u_tint & 0x000000ff)      ) / 255.0;
        float g = float((u_tint & 0x0000ff00) >>  8) / 255.0;
        float b = float((u_tint & 0x00ff0000) >> 16) / 255.0;
        vec4 tint = vec4(r, g, b, 1.0);
        color = texture(u_texture, vec2(f_uv.x, y)) * tint;
    }
END
