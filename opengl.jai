#import "GL";

DEFAULT_WINDOW_NAME :: "A hearty dish for you!";
GRAPHICS_API :: GraphicsAPI.OPENGL;

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ---------------------------------------------------------------------------------------------------------------- init
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// must be called from the thread where opengl api calls will be made from; OpenGL context is thread-local
create_graphics_context :: (using curry: *Curry) {
    curry.gl_context = SDL_GL_CreateContext(curry.window);
    if !curry.gl_context {
        log("could not create OpenGL context: %", to_string(SDL_GetError()));
        exit(1);
    }

    gl_load(*gl, SDL_GL_GetProcAddress);

    // cull back faces. CCW is considered front
    // gl_assert(glEnable(GL_CULL_FACE));
    gl_assert(glFrontFace(GL_CCW));

    // use depth buffer so stuff in back doesn't draw over stuff in front
    gl_assert(glEnable(GL_DEPTH_TEST));
    gl_assert(glDepthFunc(GL_LEQUAL));

    // msaa
    // gl_assert(glEnable(GL_MULTISAMPLE));

    // alpha blend setting
    gl_assert(glEnable(GL_BLEND));
    gl_assert(glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA));
    gl_assert(glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE));

    // TODO: this ain't the project directory
    curry.project_directory = copy_string(get_working_directory());
    curry.asset_directory = copy_string(tprint("%\\assets", curry.project_directory));

    stbi_set_flip_vertically_on_load(1);

    log("Using OpenGL version %", to_string(glGetString(GL_VERSION)));
    log("graphics vendor: %", to_string(glGetString(GL_VENDOR)));
    log("graphics renderer: %", to_string(glGetString(GL_RENDERER)));
}

delete_curry :: (curry: *Curry) {
    save_struct_to_text_file(WINDOW_SETTINGS_FILE_PATH, *curry.window_settings);    
    free(curry.project_directory); 
    free(curry.asset_directory);
    free(curry.window_name);
    SDL_GL_DeleteContext(curry.gl_context);
    SDL_DestroyWindow(curry.window);
    SDL_Quit();
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ---------------------------------------------------------------------------------------------------------------- tick
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

clear_canvas :: (clear_color: *Color3f) {
    glClearColor(clear_color.r, clear_color.g, clear_color.b, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

cache_window_data :: (using curry: *Curry) {
    SDL_GetWindowSize(window, *window_settings.width, *window_settings.height);
    SDL_GetWindowPosition(window, *window_settings.position_x, *window_settings.position_y);
}

advance_graphics_frame :: (curry: *Curry) {
    SDL_GL_SwapWindow(curry.window);
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --------------------------------------------------------------------------------------------------------------- imgui
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

imgui_opengl_render :: (curry: *Curry) {
    using curry.gui_data;

    io := ImGui.GetIO();

    fb_width := (io.DisplaySize.x * io.DisplayFramebufferScale.x);
    fb_height := (io.DisplaySize.y * io.DisplayFramebufferScale.y);
    if fb_width == 0 || fb_height == 0 return;
    draw_data := ImGui.GetDrawData();
    draw_data.ScaleClipRects(draw_data, *io.DisplayFramebufferScale);

    // graphics_settings: GraphicsAPISettings = ---;
    // cache_graphics_api_settings(*graphics_settings);

    // Setup render state: alpha-blending enabled, no face culling, no depth testing, scissor enabled, polygon fill
    glActiveTexture(GL_TEXTURE0);
    glEnable(GL_BLEND);
    glBlendEquation(GL_FUNC_ADD);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_CULL_FACE);
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_SCISSOR_TEST);
    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);

    // Setup viewport, orthographic projection matrix
    glViewport(0, 0, xx fb_width, xx fb_height);

    // TODO: understand why the example implementation pushes a new context. is it because the 
    // user callback might make allocations or...?
    // new_context: Context;
    // push_context new_context {
        ortho_projection := orthographic_projection_matrix(0, io.DisplaySize.x, io.DisplaySize.y, 0, 0, 1);
        ortho_projection = transpose(ortho_projection);

        shader_bind(*shader);
        shader_set_uniform(*shader, "Texture", cast(s32) 0);
        shader_set_uniform(*shader, "ProjMtx", ortho_projection, GL_FALSE);
        vertex_array_bind(*va);
        glBindSampler(0, 0); // Rely on combined texture/sampler state.

        // Render command lists
        for n: 0..draw_data.CmdListsCount-1 {
            cmd_list := draw_data.CmdLists[n];
            idx_buffer_offset : *ImGui.ImDrawIdx;

            gl_assert(glBindBuffer(GL_ARRAY_BUFFER, vb.render_id));
            gl_assert(glBufferData(
                GL_ARRAY_BUFFER, 
                cmd_list.VtxBuffer.Size * size_of(ImGui.ImDrawVert), 
                cmd_list.VtxBuffer.Data, 
                GL_STREAM_DRAW
            ));

            gl_assert(glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ib.render_id));
            gl_assert(glBufferData(
                GL_ELEMENT_ARRAY_BUFFER, 
                cmd_list.IdxBuffer.Size * size_of(ImGui.ImDrawIdx), 
                cmd_list.IdxBuffer.Data, 
                GL_STREAM_DRAW
            ));

            for cmd_i: 0..cmd_list.CmdBuffer.Size-1 {
                pcmd := *cmd_list.CmdBuffer.Data[cmd_i];
                if pcmd.UserCallback {
                    pcmd.UserCallback(cmd_list, pcmd);
                } else {
                    gl_assert(glBindTexture(GL_TEXTURE_2D, xx pcmd.TextureId));
                    gl_assert(glScissor(
                        xx pcmd.ClipRect.x, 
                        xx (fb_height - pcmd.ClipRect.w), 
                        xx (pcmd.ClipRect.z - pcmd.ClipRect.x), 
                        xx (pcmd.ClipRect.w - pcmd.ClipRect.y)
                    ));
                    gl_assert(glDrawElements(GL_TRIANGLES, pcmd.ElemCount, GL_UNSIGNED_SHORT, idx_buffer_offset));
                }
                idx_buffer_offset += pcmd.ElemCount;
            }
        }

        // set_graphics_api_settings(*graphics_settings);
    // }
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ---------------------------------------------------------------------------------------------------------------- draw
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

draw :: (va: *VertexArray, ib: *IndexBuffer, shader: *Shader, draw_mode: u32, start := 0, force_count := -1) {
    shader_bind(shader);
    vertex_array_bind(va);
    if ib != null {
        count : u32 = ifx force_count > -1 then cast(u32) force_count else cast(u32) ib.count;
        index_buffer_bind(ib);
        gl_assert(glDrawElements(draw_mode, count, ib.type, xx (start * gl_element_size(ib.type))));
    } else {
        count : u32 = ifx force_count > -1 then cast(u32) force_count else cast(u32) va.count;
        gl_assert(glDrawArrays(draw_mode, xx start, count));
    }
}

draw :: (sprite: *Sprite, mvp: *Matrix4) {
    shader_bind(*sprite_draw_data.shader);
    shader_set_uniform(*sprite_draw_data.shader, "u_MVP", <<mvp);
    if sprite.frame_count == 1 {
        shader_set_uniform(*sprite_draw_data.shader, "u_animYScalar", 1.0);
        shader_set_uniform(*sprite_draw_data.shader, "u_animYOffset", 0.0);
    } else {
        scalar := 1.0 / xx sprite.frame_count;
        shader_set_uniform(*sprite_draw_data.shader, "u_animYScalar", scalar);
        shader_set_uniform(*sprite_draw_data.shader, "u_animYOffset", xx sprite.frame_index * scalar);
    } 
    vertex_array_bind(*sprite_draw_data.va);
    index_buffer_bind(*sprite_draw_data.ib);
    texture_bind(*sprite.texture);
    gl_assert(glDrawElements(GL_TRIANGLES, sprite_draw_data.ib.count, sprite_draw_data.ib.type, xx 0));   
}

draw_instanced :: (va: *VertexArray, ib: *IndexBuffer, shader: *Shader, draw_mode: u32, instance_count: u32) {
    assert(instance_count > 0);
    shader_bind(shader);
    vertex_array_bind(va);
    if ib != null {
        index_buffer_bind(ib);
        gl_assert(glDrawElementsInstanced(draw_mode, ib.count, ib.type, null, instance_count));
    } else {
        gl_assert(glDrawArraysInstanced(draw_mode, 0, array.count, instance_count));
    }
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------------------------------------ viewport
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

set_viewport_for_draw :: inline (v: s64) {
    set_viewport_for_draw(viewport_rects[v]);
}

set_viewport_for_draw :: inline (using rect: ViewportRect) {
    glViewport(bottom_left.x, bottom_left.y, xx dimensions.x, xx dimensions.y);
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------------------------------------- texture
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// for if you want to not undo the tex binding tha comes before you: 
// cache the binding, do your thing, and rebind cached tex
cached_texture_render_id: s32;

// TODO: this shouldn't be opengl-specific
// https://registry.khronos.org/OpenGL-Refpages/gl4/html/glTexParameter.xhtml
TextureCreationInfo :: struct {
    filter_minification : s32 = GL_LINEAR;
    filter_magnification : s32 = GL_LINEAR;
    wrap_width : s32 = GL_CLAMP_TO_EDGE;
    wrap_height : s32 = GL_CLAMP_TO_EDGE;
    image_format := ImageFormat.NONE;
    slot : u32;
    delete_local := true;
}

texture_create :: (file_path: string, creation_info := TextureCreationInfo.{}) -> Texture {
    tex: Texture = ---;
    tex.image = image_load(file_path, creation_info.image_format);
    texture_create_on_gpu(*tex, *creation_info);
    return tex;
}

texture_create :: (image: Image, creation_info := TextureCreationInfo.{}) -> Texture {
    tex: Texture = ---;
    tex.image = image;
    texture_create_on_gpu(*tex, *creation_info);
    return tex;
}

texture_delete :: (tex: *Texture) {
    if tex.render_id != 0 then gl_assert(glDeleteTextures(1, *tex.render_id));
    // TODO: ehhh imgui texture???
    image_delete(*tex.image);
    tex.render_id = 0;
    tex.slot = 0;
}

// TODO: delete_local
texture_create_on_gpu :: (tex: *Texture, creation_info: *TextureCreationInfo) {
    tex.slot = creation_info.slot;
    tex.creation_info = <<creation_info;
    gl_assert(glGenTextures(1, *tex.render_id));
    texture_bind(tex, xx creation_info.slot);
    gl_assert(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, creation_info.filter_minification));
    gl_assert(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, creation_info.filter_magnification));
    if creation_info.wrap_width != -1
        then gl_assert(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, creation_info.wrap_width));
    if creation_info.wrap_height != -1
        then gl_assert(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, creation_info.wrap_height));
    gl_format : u32;
    gl_channel : u32;
    if tex.pixel_tag == {
    case .RGBA8;
        gl_format = GL_RGBA;
        gl_channel = GL_UNSIGNED_BYTE;
    case .R8;
        gl_format = GL_RED;
        gl_channel = GL_UNSIGNED_BYTE;
    case;
        assert(false);
    }
    // can use this to allocate space on gpu without sending image (pass nullptr)
    gl_assert(glTexImage2D(
        GL_TEXTURE_2D, 0, xx gl_format, xx tex.width, xx tex.height, 0, gl_format, gl_channel, tex.raw_data.data
    ));
}

texture_bind :: (tex: *Texture, slot: s32 = 0) {
    tex.slot = xx slot;
    gl_assert(glActiveTexture(xx (GL_TEXTURE0 + xx tex.slot)));
    gl_assert(glBindTexture(GL_TEXTURE_2D, tex.render_id));
}

texture_unbind :: () {
    gl_assert(glBindTexture(GL_TEXTURE_2D, 0));
}

texture_cache_bound :: inline () {
    gl_assert(glGetIntegerv(GL_TEXTURE_BINDING_2D, xx *cached_texture_render_id));
}

texture_bind_cached :: () {
    gl_assert(glBindTexture(GL_TEXTURE_2D, cached_texture_render_id));
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// -------------------------------------------------------------------------------------------------------- vertex array
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

cached_vertex_array_render_id: s32;

vertex_array_create :: () -> VertexArray {
    va : VertexArray = ---;
    gl_assert(glGenVertexArrays(1, *va.render_id));
    return va;
}

vertex_array_delete :: (va: *VertexArray) {
    gl_assert(glDeleteVertexArrays(1, *va.render_id));
    <<va = .{};
}

vertex_array_bind :: (va: *VertexArray) {
    gl_assert(glBindVertexArray(va.render_id));
}

vertex_array_unbind :: () {
    gl_assert(glBindVertexArray(0));
}

vertex_array_add_buffer :: (
    va: *VertexArray, vb: *VertexBuffer, $VertexType: Type, shader_handle: u32 = 0, names: ..string
) {
    vertex_array_bind(va);
    vertex_buffer_bind(vb);
    // note: this means each array can only refer to a single buffer
    va.count = vb.count;

    // TODO: normalization? good for byte-channel colors
    stride : u32 = xx size_of(VertexType);
    i := 0;
    for m : 0..type_info(VertexType).members.count-1 {
        member_layout := struct_member_type_info_to_gl_layout(*type_info(VertexType).members[m]);
        if member_layout.count == INVALID_STRUCT_MEMBER_LAYOUT_INFO.count then continue;
        location: u32;
        if names.count > i {
            param_name := temp_c_string(names[i]);
            location = deref_Any(gl_assert(glGetAttribLocation(shader_handle, param_name)), u32);
        } else {
            location = xx i;
        }
        gl_assert(glEnableVertexAttribArray(xx i));
        normalize := ifx member_layout.gl_type == GL_FLOAT then GL_FALSE else GL_TRUE;
        gl_assert(glVertexAttribPointer(
            location, xx member_layout.count, member_layout.gl_type, normalize, stride, xx member_layout.offset
        ));
        i += 1;
    }
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------------------------------- vertex buffer
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

cached_vertex_buffer_render_id: s32;

vertex_buffer_create :: (vertices: []$VertexType, usage: u32) -> VertexBuffer {
    vb : VertexBuffer = ---;
    gl_assert(glGenBuffers(1, *vb.render_id));
    gl_assert(glBindBuffer(GL_ARRAY_BUFFER, vb.render_id));
    gl_assert(glBufferData(GL_ARRAY_BUFFER, size_of(VertexType) * vertices.count, *vertices[0], usage));
    vb.count = xx vertices.count;
    return vb;
}

// usage: likely GL_STATIC_DRAW or GL_DYNAMIC_DRAW
vertex_buffer_create :: ($VertexType: Type, count: s64, usage: u32) -> VertexBuffer {
    vb : VertexBuffer = ---;
    assert(count > 0);
    gl_assert(glGenBuffers(1, *vb.render_id));
    gl_assert(glBindBuffer(GL_ARRAY_BUFFER, vb.render_id));
    gl_assert(glBufferData(GL_ARRAY_BUFFER, size_of(VertexType) * count, null, usage));
    vb.count = xx count;
    return vb;
}

vertex_buffer_create_blank :: () -> VertexBuffer {
    vb := VertexBuffer.{};
    gl_assert(glGenBuffers(1, *vb.render_id));
    return vb;
}

vertex_buffer_delete :: (vb: *VertexBuffer) {
    gl_assert(glDeleteBuffers(1, *vb.render_id));
    <<vb = .{};
}

vertex_buffer_bind :: (vb: *VertexBuffer) {
    gl_assert(glBindBuffer(GL_ARRAY_BUFFER, vb.render_id));
}

vertex_buffer_unbind :: () {
    gl_assert(glBindBuffer(GL_ARRAY_BUFFER, 0));
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// -------------------------------------------------------------------------------------------------------- index buffer
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

index_buffer_create :: (indices: []$IndexType, usage: u32) -> IndexBuffer 
    #modify { return index_type_to_gl_index_type(IndexType) != 0; }
{
    GL_INDEX_TYPE :: #run index_type_to_gl_index_type(IndexType);
    ib := IndexBuffer.{count = xx indices.count, type = GL_INDEX_TYPE };
    gl_assert(glGenBuffers(1, *ib.render_id));
    gl_assert(glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ib.render_id));
    gl_assert(glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(IndexType) * indices.count, *indices[0], usage));
    return ib;
}

index_buffer_create :: ($IndexType: Type, count: s64, usage: u32) -> IndexBuffer 
    #modify { return index_type_to_gl_index_type(IndexType) != 0; }
{
    GL_INDEX_TYPE :: #run index_type_to_gl_index_type(IndexType);
    ib := IndexBuffer.{count = xx count, type = GL_INDEX_TYPE };
    gl_assert(glGenBuffers(1, *ib.render_id));
    gl_assert(glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ib.render_id));
    gl_assert(glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(IndexType) * count, null, usage));
    return ib;
}

index_buffer_create_blank :: () -> IndexBuffer {
    ib := IndexBuffer.{};
    gl_assert(glGenBuffers(1, *ib.render_id));
    return ib;
}

index_buffer_delete :: (ib: *IndexBuffer) {
    gl_assert(glDeleteBuffers(1, *ib.render_id));
    <<ib = .{};
}

index_buffer_bind :: (ib: *IndexBuffer) {
    gl_assert(glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ib.render_id));
}

index_buffer_unbind :: () {
    gl_assert(glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0));
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// -------------------------------------------------------------------------------------------------------------- shader 
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

shader_create_vf :: (vertex: string, fragment: string) -> Shader {
    program_id := glCreateProgram();
    vertex_id := compile_shader(vertex, GL_VERTEX_SHADER);
    shader := Shader.{render_id=INVALID_SHADER_ID};
    if vertex_id == INVALID_SHADER_ID then return shader;
    // deleting intermediate representation
    defer glDeleteShader(vertex_id);
    fragment_id := compile_shader(fragment, GL_FRAGMENT_SHADER);
    if fragment_id == INVALID_SHADER_ID then return shader;
    defer glDeleteShader(fragment_id);
    glAttachShader(program_id, vertex_id);
    glAttachShader(program_id, fragment_id);
    glLinkProgram(program_id);
    glValidateProgram(program_id);
    shader.render_id = program_id;
    shader_bind(*shader);
    return shader;
}

compile_shader :: (source: string, type: u32) -> u32 {
    id := glCreateShader(type);
    shader_length : s32 = xx source.count;
    glShaderSource(id, 1, *source.data, *shader_length);
    glCompileShader(id);

    result : s32 = ---;
    glGetShaderiv(id, GL_COMPILE_STATUS, *result); 
    if !result {
        msg_length : s32 = ---;
        glGetShaderiv(id, GL_INFO_LOG_LENGTH, *msg_length);
        if msg_length <= 0 then return INVALID_SHADER_ID;
        buffer := cast(*u8) alloc(msg_length);
        defer free(buffer);
        msg := string.{xx msg_length, buffer};
        msg_length_unsigned : u32 = xx msg_length;
        glGetShaderInfoLog(id, msg_length_unsigned, *msg_length_unsigned, msg.data);
        log("compile_shader() error: %", msg);
        glDeleteShader(id);
        return INVALID_SHADER_ID;
    }

    return id;
}

shader_invalid :: (shader: *Shader) -> bool {
    return shader.render_id == INVALID_SHADER_ID;
}

shader_bind :: (shader: *Shader) {
    gl_assert(glUseProgram(shader.render_id));
}

shader_unbind :: () {
    gl_assert(glUseProgram(0));
}

type_to_shader_param_type :: ($T : Type) -> ShaderParameterType {
    #if T == {
    case s32;
        return .UNIFORM_1I;
    case float32;
        return .UNIFORM_1F;
    case Vector2;
        return .UNIFORM_2F;
    case Vector3;
        return .UNIFORM_3F;
    case Vector4;
        return .UNIFORM_4F;
    case;
        return .NONE;
    }
}

shader_set_uniform :: (shader: *Shader, name: string, uniform: $T, transpose_matrix := GL_TRUE) {
    name_id := native_XXH64(name.data, xx name.count, seed=1);
    location : s32 = -1;
    for shader.parameters {
        if it.name_id == name_id {
            location = it.location; 
            // TODO: validate type
            break;
        }
    }
    if location == -1 {
        c_name := to_c_string(name);
        defer free(c_name);
        location = deref_Any(gl_assert(glGetUniformLocation(shader.render_id, c_name)), s32);
        assert(location != -1);
        array_add(*shader.parameters, .{type_to_shader_param_type(T), location, name_id});
    }
    #if T == Matrix4 {
        set_uniform_internal(location, uniform, transpose_matrix);
    } else {
        set_uniform_internal(location, uniform);
    }
}

set_uniform_internal :: (location: s32, uniform: float32) {
    gl_assert(glUniform1f(location, uniform));
}

set_uniform_internal :: (location: s32, uniform: Vector4) {
    gl_assert(glUniform4f(location, uniform.x, uniform.y, uniform.z, uniform.w));
}

set_uniform_internal :: (location: s32, uniform: s32) {
    gl_assert(glUniform1i(location, uniform));
}

set_uniform_internal :: (location: s32, uniform: Matrix4, transpose := GL_TRUE) {
    gl_assert(glUniformMatrix4fv(location, 1, transpose, xx *uniform.floats[0]));
}

set_uniform_internal :: (location: s32, uniform: Vector3) {
    gl_assert(glUniform3f(location, uniform.x, uniform.y, uniform.z));
}

shader_delete :: (shader: *Shader) {
    gl_assert(glDeleteProgram(shader.render_id));
    array_free(shader.parameters);
}


// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------------------------------- state caching 
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

GraphicsAPISettings :: struct {
    last_active_texture: GLenum;
    last_program: GLuint;
    last_texture: GLuint;
    last_sampler: GLuint;
    last_array_buffer: GLuint;
    last_element_array_buffer: GLuint;
    last_vertex_array: GLuint;
    last_polygon_mode: [2]GLuint;
    last_viewport: [4]GLint;
    last_scissor_box : [4]GLint;
    last_blend_src_rgb: GLenum;
    last_blend_dst_rgb: GLenum;
    last_blend_src_alpha: GLenum;
    last_blend_dst_alpha: GLenum;
    last_blend_equation_rgb: GLenum;
    last_blend_equation_alpha: GLenum;
    last_enable_blend : bool;
    last_enable_cull_face : bool;
    last_enable_depth_test : bool;
    last_enable_scissor_test : bool;
}

cache_graphics_api_settings :: (using cache: *GraphicsAPISettings) {
    glGetIntegerv(GL_ACTIVE_TEXTURE, xx *last_active_texture);
    glGetIntegerv(GL_CURRENT_PROGRAM, xx *last_program);
    glGetIntegerv(GL_TEXTURE_BINDING_2D, xx *last_texture);
    glGetIntegerv(GL_SAMPLER_BINDING, xx *last_sampler);
    glGetIntegerv(GL_ARRAY_BUFFER_BINDING, xx *last_array_buffer);
    glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, xx *last_element_array_buffer);
    glGetIntegerv(GL_VERTEX_ARRAY_BINDING, xx *last_vertex_array);
    glGetIntegerv(GL_POLYGON_MODE, xx last_polygon_mode.data);
    glGetIntegerv(GL_VIEWPORT, last_viewport.data);
    glGetIntegerv(GL_SCISSOR_BOX, last_scissor_box.data);
    glGetIntegerv(GL_BLEND_SRC_RGB, xx *last_blend_src_rgb);
    glGetIntegerv(GL_BLEND_DST_RGB, xx *last_blend_dst_rgb);
    glGetIntegerv(GL_BLEND_SRC_ALPHA, xx *last_blend_src_alpha);
    glGetIntegerv(GL_BLEND_DST_ALPHA, xx *last_blend_dst_alpha);
    glGetIntegerv(GL_BLEND_EQUATION_RGB, xx *last_blend_equation_rgb);
    glGetIntegerv(GL_BLEND_EQUATION_ALPHA, xx *last_blend_equation_alpha);
    last_enable_blend = glIsEnabled(GL_BLEND);
    last_enable_cull_face = glIsEnabled(GL_CULL_FACE);
    last_enable_depth_test = glIsEnabled(GL_DEPTH_TEST);
    last_enable_scissor_test = glIsEnabled(GL_SCISSOR_TEST);
}

set_graphics_api_settings :: (using cache: *GraphicsAPISettings) {
    glUseProgram(last_program);
    glBindTexture(GL_TEXTURE_2D, last_texture);
    glBindSampler(0, last_sampler);
    glActiveTexture(last_active_texture);
    glBindVertexArray(last_vertex_array);
    glBindBuffer(GL_ARRAY_BUFFER, last_array_buffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, last_element_array_buffer);
    glBlendEquationSeparate(last_blend_equation_rgb, last_blend_equation_alpha);
    glBlendFuncSeparate(last_blend_src_rgb, last_blend_dst_rgb, last_blend_src_alpha, last_blend_dst_alpha);
    if last_enable_blend        
        then glEnable(GL_BLEND);         
        else glDisable(GL_BLEND);
    if last_enable_cull_face   
        then glEnable(GL_CULL_FACE);     
        else glDisable(GL_CULL_FACE);
    if last_enable_depth_test   
        then glEnable(GL_DEPTH_TEST);    
        else glDisable(GL_DEPTH_TEST);
    if last_enable_scissor_test 
        then glEnable(GL_SCISSOR_TEST);  
        else glDisable(GL_SCISSOR_TEST);
    glPolygonMode(GL_FRONT_AND_BACK, last_polygon_mode[0]);
    glViewport(last_viewport[0], last_viewport[1], xx last_viewport[2], xx last_viewport[3]);
    glScissor(last_scissor_box[0], last_scissor_box[1], xx last_scissor_box[2], xx last_scissor_box[3]);
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------------------------------------- helpers 
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

StructMemberLayoutInfo :: struct {
    gl_type: u32;
    count: s16;
    offset: s16;
}

INVALID_STRUCT_MEMBER_LAYOUT_INFO :: StructMemberLayoutInfo.{0, -1, 0};

index_type_to_gl_index_type :: (T : Type) -> u32 {
    if T == {
    case u8;
        return GL_UNSIGNED_BYTE;
    case u16; 
        return GL_UNSIGNED_SHORT;
    case u32;
        return GL_UNSIGNED_INT;
    case;
        assert(false);
    }
    return 0;
}

gl_element_size :: (gl_type : u32) -> u32 {
    if gl_type == {
    case GL_FLOAT;
        return size_of(float32);
    case GL_UNSIGNED_INT;
        return size_of(u32);
    case GL_UNSIGNED_SHORT;
        return size_of(u16);
    case GL_UNSIGNED_BYTE;
        return size_of(u8);
    case;
        assert(false);
    }
    return 0;
}

type_info_to_gl_layout :: (info: *Type_Info) -> StructMemberLayoutInfo {
    if info.type == .STRUCT {
        info_struct := cast(*Type_Info_Struct) info;
        // NOTE: this tries to avoid issues by checking member flags, but it may run into issues if
        // a struct's members aren't laid out s.t. the actual backing data is at the top and the #place's come
        // after, since we're iterating forward over the struct.
        size_count : s64;
        member_count : s16;
        for i : 0..info_struct.members.count-1 {
            member := *info_struct.members[i];
            // if member.flags != 0 then continue;
            next_size := size_count + member.type.runtime_size;
            if next_size > info_struct.runtime_size then break;
            // all members must be one of these primitives
            assert(member.type.type == .INTEGER || member.type.type == .FLOAT);
            if i > 0 {
                // all members must be uniform
                assert(
                    info_struct.members[0].type.type == member.type.type 
                    && info_struct.members[0].type.runtime_size == member.type.runtime_size
                );
            }
            size_count = next_size;
            member_count += 1;
        }

        base_info := type_info_to_gl_layout(info_struct.members[0].type);
        base_info.count = member_count;
        return base_info;
    } else if info.type == {
    case .INTEGER;
        info_int := cast(*Type_Info_Integer) info;
        if info_int.runtime_size == {
        case 1;
            if info_int.signed then return .{GL_BYTE, 1, 0}; else return .{GL_UNSIGNED_BYTE, 1, 0};
        case 2;
            if info_int.signed then return .{GL_SHORT, 1, 0}; else return .{GL_UNSIGNED_SHORT, 1, 0};
        case 4;
            if info_int.signed then return .{GL_INT, 1, 0}; else return .{GL_UNSIGNED_INT, 1, 0};
        case;
            assert(false);
        }
    case .FLOAT;
        if info.runtime_size == 4 then return .{GL_FLOAT, 1, 0}; else return .{GL_DOUBLE, 1, 0};
    case;
    }
    return INVALID_STRUCT_MEMBER_LAYOUT_INFO;
}

struct_member_type_info_to_gl_layout :: (info: *Type_Info_Struct_Member) -> StructMemberLayoutInfo {
    // if info.flags != 0 then return INVALID_STRUCT_MEMBER_LAYOUT_INFO;
    out_info := type_info_to_gl_layout(info.type);
    out_info.offset = xx info.offset_in_bytes;
    return out_info;
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --------------------------------------------------------------------------------------------------------------- debug
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

gl_log_error :: (error: u32, caller_loc := #caller_location) {
    log("[opengl error] :: [0x%] at %", formatInt(error, base=16, minimum_digits=4), caller_loc);
}

gl_clear_errors :: () {
    ITER_MAX :: 10;
    iter_count := 0;
    while glGetError() != GL_NO_ERROR && iter_count < ITER_MAX { 
        iter_count += 1;
    }
}

gl_log_errors :: (caller_loc := #caller_location) -> bool {
    ITER_MAX :: 10;
    iter_count := 0;
    error := glGetError();
    any_errors := false;
    while error != GL_NO_ERROR && iter_count < ITER_MAX {
        any_errors = true;
        gl_log_error(error, caller_loc);
        error = glGetError();
        iter_count += 1;
    }
    return any_errors;
}

gl_assert :: ($opengl_code : Code, caller_loc := #caller_location) -> Any #expand {
    #if GRAPHICS_API_DEBUG {
        gl_clear_errors();
        retval := #insert opengl_code;
        assert(!gl_log_errors(caller_loc));
        return retval;
    } else {
        return #insert opengl_code;
    }
}

