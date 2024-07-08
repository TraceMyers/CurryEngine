
VertexField :: enum {
    UV_2F; 
    COLOR_4F;
    COLOR_4B;
    NORMAL_3F;
}

generate_vertex_fields :: (fields: []VertexField) -> string {
    builder: String_Builder;
    for fields {
        if it == {
        case .UV_2F;
            print_to_builder(*builder, "uv: Vector2;\n");
        case .COLOR_4F;
            print_to_builder(*builder, "color: Color4f;\n");
        case .COLOR_4B;
            print_to_builder(*builder, "color: Color4b;\n");
        case .NORMAL_3F;
            print_to_builder(*builder, "normal: Vector3;\n");
        }
    }
    return builder_to_string(*builder);
}

Vertex :: struct($position_dimensions: int, $fields: ..VertexField) {
    #if VertexPositionType != void then position: VertexPositionType;
    #insert #run generate_vertex_fields(fields);
    VertexPositionType :: #run vertex_position_type(position_dimensions);
}

VertexBuffer :: struct {
    render_id: u32;
    count: u32;
}

IndexBuffer :: struct {
    render_id: u32;
    count: u32;
    type: u32;
}

VertexArray :: struct {
    render_id: u32;
    count: u32;
}

Texture :: struct {
    render_id: u32;
    slot: u32;
    using image: Image;
    creation_info: TextureCreationInfo;
}

INVALID_SHADER_ID : u32 : U32_MAX;

ShaderParameterType :: enum {
    NONE;
    UNIFORM_1I;
    UNIFORM_1F;
    UNIFORM_2F;
    UNIFORM_3F;
    UNIFORM_4F;
}

ShaderParameter :: struct {
    type := ShaderParameterType.NONE;
    location : s32;
    name_id : u64;
}

Shader :: struct {
    render_id : u32;
    parameters : [..]ShaderParameter;
}


find_vertex_field :: (field: VertexField, fields: []VertexField) -> s64 {
    for i : 0..fields.count-1 {
        if fields[i] == field then return i;
    }
    return -1;
}

vertex_position_type :: ($dimensions: int) -> Type {
    if dimensions == {
    case 1;
        return float32;
    case 2;
        return Vector2;
    case 3;
        return Vector3;
    case 4;
        return Vector4;
    }
    return void;
}

