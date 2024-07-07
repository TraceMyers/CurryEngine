// Workspace: Target Program

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/CurryEngine/pixel.jai:500.
//
#place r;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/CurryEngine/pixel.jai:500.
//
#place r;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/CurryEngine/pixel.jai:500.
//
#place r;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/CurryEngine/pixel.jai:500.
//
#place r;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/CurryEngine/pixel.jai:500.
//
#place r;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/CurryEngine/pixel.jai:500.
//
#place r;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/CurryEngine/pixel.jai:502.
//
#place b;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/CurryEngine/pixel.jai:503.
//
#place a;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/CurryEngine/pixel.jai:503.
//
#place a;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/CurryEngine/pixel.jai:500.
//
#place r;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/CurryEngine/pixel.jai:502.
//
#place b;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/CurryEngine/pixel.jai:500.
//
#place r;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/CurryEngine/pixel.jai:502.
//
#place b;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/CurryEngine/pixel.jai:500.
//
#place r;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/CurryEngine/pixel.jai:500.
//
#place r;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/CurryEngine/pixel.jai:500.
//
#place r;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/CurryEngine/pixel.jai:500.
//
#place r;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/CurryEngine/render_types.jai:28.
//
color: Color4b;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/CurryEngine/render_types.jai:28.
//
uv: Vector2;
color: Color4b;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/CurryEngine/pixel.jai:117.
//
pixel_type_to_tag :: ($T: Type) -> PixelTag {
    if T == {
case R3G3B2; return .R3G3B2;
case R5G5B5; return .R5G5B5;
case R5G6B5; return .R5G6B5;
case R5G5B5A1; return .R5G5B5A1;
case A1R5G5B5; return .A1R5G5B5;
case R4G4B4A4; return .R4G4B4A4;
case R8; return .R8;
case RA8; return .RA8;
case R16; return .R16;
case RGB8; return .RGB8;
case BGR8; return .BGR8;
case RGBP8; return .RGBP8;
case BGRP8; return .BGRP8;
case RGBA8; return .RGBA8;
case ARGB8; return .ARGB8;
case ABGR8; return .ABGR8;
case BGRA8; return .BGRA8;
case RGBA32; return .RGBA32;
case R32f; return .R32f;
case RG32f; return .RG32f;
case RGB32f; return .RGB32f;
case RGBA32f; return .RGBA32f;
case R64f; return .R64f;
}}pixel_tag_to_type :: (e: $PixelTag) -> Type {
    if e == {
case .R3G3B2; return R3G3B2;
case .R5G5B5; return R5G5B5;
case .R5G6B5; return R5G6B5;
case .R5G5B5A1; return R5G5B5A1;
case .A1R5G5B5; return A1R5G5B5;
case .R4G4B4A4; return R4G4B4A4;
case .R8; return R8;
case .RA8; return RA8;
case .R16; return R16;
case .RGB8; return RGB8;
case .BGR8; return BGR8;
case .RGBP8; return RGBP8;
case .BGRP8; return BGRP8;
case .RGBA8; return RGBA8;
case .ARGB8; return ARGB8;
case .ABGR8; return ABGR8;
case .BGRA8; return BGRA8;
case .RGBA32; return RGBA32;
case .R32f; return R32f;
case .RG32f; return RG32f;
case .RGB32f; return RGB32f;
case .RGBA32f; return RGBA32f;
case .R64f; return R64f;
}}pixel_size :: (e: PixelTag) -> s64 {
    if e == {
case .R3G3B2; return size_of(R3G3B2);
case .R5G5B5; return size_of(R5G5B5);
case .R5G6B5; return size_of(R5G6B5);
case .R5G5B5A1; return size_of(R5G5B5A1);
case .A1R5G5B5; return size_of(A1R5G5B5);
case .R4G4B4A4; return size_of(R4G4B4A4);
case .R8; return size_of(R8);
case .RA8; return size_of(RA8);
case .R16; return size_of(R16);
case .RGB8; return size_of(RGB8);
case .BGR8; return size_of(BGR8);
case .RGBP8; return size_of(RGBP8);
case .BGRP8; return size_of(BGRP8);
case .RGBA8; return size_of(RGBA8);
case .ARGB8; return size_of(ARGB8);
case .ABGR8; return size_of(ABGR8);
case .BGRA8; return size_of(BGRA8);
case .RGBA32; return size_of(RGBA32);
case .R32f; return size_of(R32f);
case .RG32f; return size_of(RG32f);
case .RGB32f; return size_of(RGB32f);
case .RGBA32f; return size_of(RGBA32f);
case .R64f; return size_of(R64f);
}}pixel_channels :: (e: PixelTag) -> s64 {
    if e == {
case .R3G3B2; return R3G3B2.FIELD_COUNT;
case .R5G5B5; return R5G5B5.FIELD_COUNT;
case .R5G6B5; return R5G6B5.FIELD_COUNT;
case .R5G5B5A1; return R5G5B5A1.FIELD_COUNT;
case .A1R5G5B5; return A1R5G5B5.FIELD_COUNT;
case .R4G4B4A4; return R4G4B4A4.FIELD_COUNT;
case .R8; return R8.FIELD_COUNT;
case .RA8; return RA8.FIELD_COUNT;
case .R16; return R16.FIELD_COUNT;
case .RGB8; return RGB8.FIELD_COUNT;
case .BGR8; return BGR8.FIELD_COUNT;
case .RGBP8; return RGBP8.FIELD_COUNT;
case .BGRP8; return BGRP8.FIELD_COUNT;
case .RGBA8; return RGBA8.FIELD_COUNT;
case .ARGB8; return ARGB8.FIELD_COUNT;
case .ABGR8; return ABGR8.FIELD_COUNT;
case .BGRA8; return BGRA8.FIELD_COUNT;
case .RGBA32; return RGBA32.FIELD_COUNT;
case .R32f; return R32f.FIELD_COUNT;
case .RG32f; return RG32f.FIELD_COUNT;
case .RGB32f; return RGB32f.FIELD_COUNT;
case .RGBA32f; return RGBA32f.FIELD_COUNT;
case .R64f; return R64f.FIELD_COUNT;
}}

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/CurryEngine/render_types.jai:28.
//
uv: Vector2;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/CurryEngine/struct_utilities.jai:46.
//
if String.compare(member_name, "width") == 0 { s.width = cast(s32) String.parse_int(*value); }
else if String.compare(member_name, "height") == 0 { s.height = cast(s32) String.parse_int(*value); }
else if String.compare(member_name, "position_x") == 0 { s.position_x = cast(s32) String.parse_int(*value); }
else if String.compare(member_name, "position_y") == 0 { s.position_y = cast(s32) String.parse_int(*value); }
else if String.compare(member_name, "fullscreen") == 0 { s.fullscreen = cast(bool) String.parse_bool(*value); }
else if String.compare(member_name, "clear_color_r") == 0 { s.clear_color_r = cast(float32) String.parse_float(*value); }
else if String.compare(member_name, "clear_color_g") == 0 { s.clear_color_g = cast(float32) String.parse_float(*value); }
else if String.compare(member_name, "clear_color_b") == 0 { s.clear_color_b = cast(float32) String.parse_float(*value); }

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/CurryEngine/struct_utilities.jai:121.
//
print_to_builder(*file_builder, "width = %\n", s.width);
print_to_builder(*file_builder, "height = %\n", s.height);
print_to_builder(*file_builder, "position_x = %\n", s.position_x);
print_to_builder(*file_builder, "position_y = %\n", s.position_y);
print_to_builder(*file_builder, "fullscreen = %\n", s.fullscreen);
print_to_builder(*file_builder, "clear_color_r = %\n", s.clear_color_r);
print_to_builder(*file_builder, "clear_color_g = %\n", s.clear_color_g);
print_to_builder(*file_builder, "clear_color_b = %\n", s.clear_color_b);
