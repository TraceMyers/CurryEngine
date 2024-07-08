
// masked pixel types individually note bits per channel
R3G3B2   :: MaskedPixel(3, 3, 2, 0, ._0, ._1, ._2, .NONE);
R5G5B5   :: MaskedPixel(5, 5, 5, 0, ._0, ._1, ._2, .NONE);
R5G6B5   :: MaskedPixel(5, 6, 5, 0, ._0, ._1, ._2, .NONE);
R5G5B5A1 :: MaskedPixel(5, 5, 5, 1, ._0, ._1, ._2, ._3);
A1R5G5B5 :: MaskedPixel(5, 5, 5, 1, ._1, ._2, ._3, ._0);
R4G4B4A4 :: MaskedPixel(4, 4, 4, 4, ._0, ._1, ._2, ._3);

// uniform pixel types note bits per channel at the end 
R8       :: UniformPixel(u8, ._0, .NONE, .NONE, .NONE);
RA8      :: UniformPixel(u8, ._0, .NONE, .NONE, ._1);
R16      :: UniformPixel(u16, ._0, .NONE, .NONE, .NONE);
RGB8     :: UniformPixel(u8, ._0, ._1, ._2, .NONE);
BGR8     :: UniformPixel(u8, ._2, ._1, ._0, .NONE);
RGBP8    :: UniformPixel(u8, ._0, ._1, ._2, .NONE, true);
BGRP8    :: UniformPixel(u8, ._2, ._1, ._0, .NONE, true);
RGBA8    :: UniformPixel(u8, ._0, ._1, ._2, ._3);
ARGB8    :: UniformPixel(u8, ._1, ._2, ._3, ._0);
ABGR8    :: UniformPixel(u8, ._3, ._2, ._1, ._0);
BGRA8    :: UniformPixel(u8, ._2, ._1, ._0, ._3);
RGBA32   :: UniformPixel(u32, ._0, ._1, ._2, ._3);
R32f     :: UniformPixel(float32, ._0, .NONE, .NONE, .NONE);
RG32f    :: UniformPixel(float32, ._0, ._1, .NONE, .NONE);
RGB32f   :: UniformPixel(float32, ._0, ._1, ._2, .NONE);
RGBA32f  :: UniformPixel(float32, ._0, ._1, ._2, ._3);
R64f     :: UniformPixel(float64, ._0, .NONE, .NONE, .NONE);

// add a new name here to generate a new pixel type alias
// for masked types, use the pattern: (channel, bits, channel, bits...) as in "R5G6B5"
// for uniform types, use the patttern: (channel, channel, .., 8/16/32/64 bits per channel) as in "RGBA8"
// if a name could create either a uniform or masked type alies, it will choose uniform
PixelTag :: enum {
    R3G3B2;
    R5G5B5;
    R5G6B5;
    R5G5B5A1;
    A1R5G5B5;
    R4G4B4A4;
    R8;
    RA8;
    R16;
    RGB8;
    BGR8;
    RGBP8;
    BGRP8;
    RGBA8;
    ARGB8;
    ABGR8;
    BGRA8;
    RGBA32;
    R32f;
    RG32f;
    RGB32f;
    RGBA32f;
    R64f;
}

generate_pixel_type_conversions :: () -> string {
    info := cast(*Type_Info_Enum) type_info(PixelTag);
    builder : String_Builder;
    
    // write conversion procedure for pixel type to pixel tag
    // ----------------------------------------------------------------
    print_to_builder(*builder,
#string END
pixel_type_to_tag :: ($T: Type) -> PixelTag {
    if T == {
END);
    for name : info.names {
        print_to_builder(*builder, "case %; return .%;\n", name, name);
    }
    print_to_builder(*builder, "}}");
    // ----------------------------------------------------------------

    // write conversion procedure for pixel tag to pixel type
    // ----------------------------------------------------------------
    print_to_builder(*builder,
#string END
pixel_tag_to_type :: (e: $PixelTag) -> Type {
    if #complete e == {
END);
    for name : info.names {
        print_to_builder(*builder, "case .%; return %;\n", name, name);
    }
    print_to_builder(*builder, "}}");
    // ----------------------------------------------------------------

    // write procedure to get the size of a pixel from a pixel tag
    // ----------------------------------------------------------------
    print_to_builder(*builder,
#string END
pixel_size :: (e: PixelTag) -> s64 {
    if #complete e == {
END);
    for name : info.names {
        print_to_builder(*builder, "case .%; return size_of(%);\n", name, name);
    }
    print_to_builder(*builder, "}}");
    // ----------------------------------------------------------------

    // write procedure to get the number of channels in a pixel from a pixel tag
    // ----------------------------------------------------------------
    print_to_builder(*builder,
#string END 
pixel_channels :: (e: PixelTag) -> s64 {
    if #complete e == {
END);
    for name : info.names {
        print_to_builder(*builder, "case .%; return %.FIELD_COUNT;\n", name, name);
    }
    print_to_builder(*builder, "}}");
    // ----------------------------------------------------------------
    return builder_to_string(*builder);
}

#insert #run generate_pixel_type_conversions();

Color4b :: struct {
    r : u8 = 0;
    g : u8 = 0;
    b : u8 = 0;
    a : u8 = 255;
}

Color4f :: struct {
    r := 0.0;
    g := 0.0;
    b := 0.0;
    a := 1.0;
}

Color3f :: struct {
    r := 0.0;
    g := 0.0;
    b := 0.0;
}

pixel2color4b :: inline (p: $PxType/interface PixelBase) -> Color4b {
    return cast,force(Color4b) convert_pixel(p, RGBA8);
}

pixel2color4f :: inline (p: $PxType/interface PixelBase) -> Color4f {
    return cast,force(Color4f) convert_pixel(p, RGBA32f);
}

pixel2color3f :: inline (p: $PxType/interface PixelBase) -> Color3f {
    return cast,force(Color3f) convert_pixel(p, RGB32f);
}

COLOR4F_RED     :: Color4f.{r=1.0};
COLOR4F_GREEN   :: Color4f.{               g=1.0};
COLOR4F_BLUE    :: Color4f.{                              b=1.0};
COLOR4F_BLACK   :: Color4f.{};
COLOR4F_GRAY    :: Color4f.{r=128.0/255.0, g=128.0/255.0, b=128.0/255.0};
COLOR4F_WHITE   :: Color4f.{r=1.0,         g=1.0,         b=1.0};
COLOR4F_PINK    :: Color4f.{r=1.0,         g= 20.0/255.0, b=147.0/255.0};
COLOR4F_ORANGE  :: Color4f.{r=1.0,         g=128.0/255.0};
COLOR4F_YELLOW  :: Color4f.{r=1.0,         g=1.0};
COLOR4F_VIOLET  :: Color4f.{r=148.0/255.0,                b=211.0/255.0}; 
COLOR4F_TEAL    :: Color4f.{               g=128.0/255.0, b=128.0/255.0};
COLOR4F_SKY     :: Color4f.{r=135.0/255.0, g=206.0/255.0, b=235.0/255.0};
COLOR4F_SEA     :: Color4f.{r= 46.0/255.0, g=139.0/255.0, b= 87.0/255.0};
COLOR4F_SIENNA  :: Color4f.{r=160.0/255.0, g= 82.0/255.0, b= 45.0/255.0};
COLOR4F_SALMON  :: Color4f.{r=250.0/255.0, g=128.0/255.0, b=114.0/255.0};
COLOR4F_WOOD    :: Color4f.{r=222.0/255.0, g=184.0/255.0, b=135.0/255.0};

COLOR4B_RED     :: Color4b.{r=255};
COLOR4B_GREEN   :: Color4b.{        g=255};
COLOR4B_BLUE    :: Color4b.{                b=255};
COLOR4B_BLACK   :: Color4b.{};
COLOR4B_GRAY    :: Color4b.{r=128,  g=128,  b=128};
COLOR4B_WHITE   :: Color4b.{r=255,  g=255,  b=255};
COLOR4B_PINK    :: Color4b.{r=255,  g= 20,  b=147};
COLOR4B_ORANGE  :: Color4b.{r=255,  g=128};
COLOR4B_YELLOW  :: Color4b.{r=255,  g=255};
COLOR4B_VIOLET  :: Color4b.{r=148,          b=211}; 
COLOR4B_TEAL    :: Color4b.{        g=128,  b=128};
COLOR4B_SKY     :: Color4b.{r=135,  g=206,  b=235};
COLOR4B_SEA     :: Color4b.{r= 46,  g=139,  b= 87};
COLOR4B_SIENNA  :: Color4b.{r=160,  g= 82,  b= 45};
COLOR4B_SALMON  :: Color4b.{r=250,  g=128,  b=114};
COLOR4B_WOOD    :: Color4b.{r=222,  g=184,  b=135};

PixelFieldLocation :: enum u8 {
    NONE :: 0x0;
    _0   :: 0x1;
    _1   :: 0x2;
    _2   :: 0x4;
    _3   :: 0x8;
}

PixelField :: enum u8 {R; G; B; A;}

determine_pixel_backing_type :: (r_bits: u8, g_bits: u8, b_bits: u8, a_bits: u8) -> Type {
    backing_size := r_bits + g_bits + b_bits + a_bits;
    if backing_size <= 8 {
        return u8;
    } else if backing_size <= 16 {
        return u16;
    } else if backing_size <= 32 {
        return u32;
    } else {
        return void;
    }
}

pixel_masks :: (
    r_bits: u8, 
    g_bits: u8, 
    b_bits: u8, 
    a_bits: u8, 
    r_location: PixelFieldLocation, 
    g_location: PixelFieldLocation, 
    b_location: PixelFieldLocation, 
    a_location: PixelFieldLocation,
    pad_least_significant : bool,
    $BackingType: Type
) ->[4]BackingType {
    assert(r_bits + g_bits + b_bits + a_bits <= size_of(BackingType) * 8);

    turn_order := PixelField.[.R, .G, .B, .A];
    locations := u8.[xx r_location, xx g_location, xx b_location, xx a_location];
    NO_LOCATION :: 255;
    for *location : locations {
        if <<location == cast(u8)PixelFieldLocation.NONE {
            <<location = NO_LOCATION;
        }
    }
    // sort so we can pack masks into the BackingType (u8, u16, etc...) in the field order (rgb, abgr, etc..) requested
    for i : 0..2 {
        for j : i+1..3 {
            if locations[j] < locations[i] {
                locations[i], locations[j] = locations[j], locations[i];
                turn_order[i], turn_order[j] = turn_order[j], turn_order[i];
            }
        }
    }

    masks := BackingType.[0, 0, 0, 0];
    mask_location : BackingType = xx (size_of(BackingType) * 8 - 1);
    if !pad_least_significant {
        bit_count_sum := r_bits + g_bits + b_bits + a_bits;
        leading_zero_count := size_of(BackingType) * 8 - bit_count_sum;
        mask_location -= leading_zero_count;
    }
    for i : 0..turn_order.count-1 {
        if locations[i] == NO_LOCATION then break;
        field_index := turn_order[i];
        bit_count : u8 = ---;
        if field_index == {
        case PixelField.R;
            bit_count = r_bits;
        case PixelField.G;
            bit_count = g_bits;
        case PixelField.B;
            bit_count = b_bits;
        case PixelField.A;
            bit_count = a_bits;
        case;
            assert(false);
        }
        end_shift := mask_location - bit_count + 1;
        for bit_shift : end_shift..mask_location {
            masks[xx field_index] |= cast(BackingType) 1 << bit_shift;
        }
        mask_location -= bit_count;
    }

    return masks;
}

pixel_masks :: (
    $r_bits: u8, 
    $g_bits: u8, 
    $b_bits: u8, 
    $a_bits: u8, 
    $r_location: PixelFieldLocation, 
    $g_location: PixelFieldLocation, 
    $b_location: PixelFieldLocation, 
    $a_location: PixelFieldLocation,
    $pad_least_significant : bool
) -> [4]$BackingType #modify {
    // NOTE: assumes parameter validity check already mostly done in MaskedPixel type instantiation / modify
    BackingType = determine_pixel_backing_type(r_bits, g_bits, b_bits, a_bits);
    return BackingType != void;
} {
    return pixel_masks(
        r_bits, 
        g_bits, 
        b_bits, 
        a_bits, 
        r_location, 
        g_location, 
        b_location, 
        a_location, 
        pad_least_significant, 
        BackingType
    );
}

trailing_zeroes :: (mask: $T) -> u8 {
    BIT_WIDTH :: size_of(T) * 8;
    tz_count : u8;
    moving_bit : T = 1;
    while (mask & moving_bit) == 0 && tz_count < BIT_WIDTH {
        tz_count += 1;
        moving_bit <<= 1;
    }
    return tz_count;
}

PixelBase :: struct {}

MaskedPixel :: struct(
    // how many bits per field
    $r_bits: u8, 
    $g_bits: u8, 
    $b_bits: u8, 
    $a_bits: u8, 
    // order the fields
    $r_location: PixelFieldLocation, 
    $g_location: PixelFieldLocation, 
    $b_location: PixelFieldLocation, 
    $a_location: PixelFieldLocation,
    // if padding is needed, should we pad the least significant or most significant bits?
    $pad_least_significant := true
) #modify {
    size_sum := r_bits + g_bits + b_bits + a_bits;
    size_ok := size_sum > 0 && size_sum <= 64;

    no_alias := 
        (r_location & g_location) | (r_location & b_location) | (r_location & a_location)
        | (g_location & b_location) | (g_location & a_location) | (b_location & a_location) == 0;

    all_fields := r_location | g_location | b_location | a_location;
    any_fields := all_fields != 0;

    // if a field has a location, it must have bits, and vice-versa
    r_match := !((r_location != 0) ^ (r_bits != 0));
    g_match := !((g_location != 0) ^ (g_bits != 0));
    b_match := !((b_location != 0) ^ (b_bits != 0));
    a_match := !((a_location != 0) ^ (a_bits != 0));
    valid_location_bits := r_match & g_match & b_match & a_match;

    max_field := max(cast(u8)r_location, cast(u8)g_location);
    max_field = max(max_field, xx b_location);
    max_field = max(max_field, xx a_location);
    moving_bit := max_field;
    no_gaps := true;
    while moving_bit > 0 {
        no_gaps &= (moving_bit & cast(u8)all_fields) != 0;
        moving_bit >>= 1;
    }

    valid := size_ok && no_alias && any_fields && no_gaps && valid_location_bits;
    if !valid then log(
        "MAKE TYPE ERROR: size ok: %, no alias: %, any fields: %, no gaps: %, bits match locations: %", 
        size_ok, no_alias, any_fields, no_gaps, valid_location_bits
    );
    return valid;
} {
    IS_UNIFORM :: false;
    IS_MASKED :: true;
    R_INDEX :: #run uniform_field_index(.R, r_location, g_location, b_location, a_location);
    G_INDEX :: #run uniform_field_index(.G, r_location, g_location, b_location, a_location);
    B_INDEX :: #run uniform_field_index(.B, r_location, g_location, b_location, a_location);
    A_INDEX :: #run uniform_field_index(.A, r_location, g_location, b_location, a_location);
    HAS_R :: #run R_INDEX != -1;
    HAS_G :: #run G_INDEX != -1;
    HAS_B :: #run B_INDEX != -1;
    HAS_A :: #run A_INDEX != -1;
    FIELD_COUNT : u8 : cast(u8) HAS_R + cast(u8) HAS_G + cast(u8) HAS_B + cast(u8) HAS_A;
    IS_GREY :: HAS_R && !HAS_G && !HAS_B;
    FieldType :: #run determine_pixel_backing_type(r_bits, g_bits, b_bits, a_bits);
    MASKS : [4]FieldType : #run pixel_masks(
        r_bits, g_bits, b_bits, a_bits, r_location, g_location, b_location, a_location, pad_least_significant
    );
    BIT_WIDTHS :: u8.[r_bits, g_bits, b_bits, a_bits];
    TRAILING_ZEROES :: u8.[
        #run trailing_zeroes(MASKS[0]), 
        #run trailing_zeroes(MASKS[1]),
        #run trailing_zeroes(MASKS[2]), 
        #run trailing_zeroes(MASKS[3])
    ];

    using #as base : PixelBase;
    c: FieldType;
}

type_is_pixel_field :: (FieldType: Type) -> bool {
    return FieldType == u8 || FieldType == u16 || FieldType == u32 || FieldType == float32 || FieldType == float64;
}

field_location_to_index :: (location: PixelFieldLocation) -> s8 {
    if #complete location == {
    case .NONE;
        return -1;
    case ._0;
        return 0;
    case ._1;
        return 1;
    case ._2;
        return 2;
    case ._3;
        return 3;
    }
}

uniform_field_index :: (
    field: PixelField,
    r_location: PixelFieldLocation,
    g_location: PixelFieldLocation,
    b_location: PixelFieldLocation,
    a_location: PixelFieldLocation
) -> s8 {
    if #complete field == {
    case .R;
        return field_location_to_index(r_location);
    case .G;
        return field_location_to_index(g_location);
    case .B;
        return field_location_to_index(b_location);
    case .A;
        return field_location_to_index(a_location);
    }
    assert(false);
    return -1;
}

uniform_field_index :: (field: PixelField, $UniformPxType: Type) -> s8 {
    if field == {
    case .R;
        return UniformPxType.R_INDEX;
    case .G;
        return UniformPxType.G_INDEX;
    case .B;
        return UniformPxType.B_INDEX;
    case .A;
        return UniformPxType.A_INDEX;
    }
    assert(false);
    return -1;
}


UniformPixel :: struct(
    $FieldType: Type,
    $r_location: PixelFieldLocation,
    $g_location: PixelFieldLocation,
    $b_location: PixelFieldLocation,
    $a_location: PixelFieldLocation,
    $pad_once_at_end := false
) #modify {
    type_ok := type_is_pixel_field(FieldType);
    no_alias := 
        (r_location & g_location) | (r_location & b_location) | (r_location & a_location)
        | (g_location & b_location) | (g_location & a_location) | (b_location & a_location) == 0;
    all_fields := r_location | g_location | b_location | a_location;
    any_fields := all_fields != 0;
    return type_ok && no_alias && any_fields;
} {
    IS_UNIFORM :: true;
    IS_MASKED :: false;
    R_INDEX :: #run uniform_field_index(.R, r_location, g_location, b_location, a_location);
    G_INDEX :: #run uniform_field_index(.G, r_location, g_location, b_location, a_location);
    B_INDEX :: #run uniform_field_index(.B, r_location, g_location, b_location, a_location);
    A_INDEX :: #run uniform_field_index(.A, r_location, g_location, b_location, a_location);
    HAS_R :: R_INDEX != -1;
    HAS_G :: G_INDEX != -1;
    HAS_B :: B_INDEX != -1;
    HAS_A :: A_INDEX != -1;
    FIELD_COUNT : u8 : cast(u8) HAS_R + cast(u8) HAS_G + cast(u8) HAS_B + cast(u8) HAS_A;
    IS_GREY :: (R_INDEX != -1) && (G_INDEX == -1) && (B_INDEX == -1);

    using #as base : PixelBase;

    #if r_location == ._0 then r: FieldType;
    else #if g_location == ._0 then g: FieldType;
    else #if b_location == ._0 then b: FieldType;
    else #if a_location == ._0 then a: FieldType;

    #if r_location == ._1 then r: FieldType;
    else #if g_location == ._1 then g: FieldType;
    else #if b_location == ._1 then b: FieldType;
    else #if a_location == ._1 then a: FieldType;

    #if r_location == ._2 then r: FieldType;
    else #if g_location == ._2 then g: FieldType;
    else #if b_location == ._2 then b: FieldType;
    else #if a_location == ._2 then a: FieldType;

    #if r_location == ._3 then r: FieldType;
    else #if g_location == ._3 then g: FieldType;
    else #if b_location == ._3 then b: FieldType;
    else #if a_location == ._3 then a: FieldType;

    #if pad_once_at_end then padding: FieldType;

    #if r_location == ._0 then #insert "#place r;components: [FIELD_COUNT]FieldType = ---;";
    #if g_location == ._0 then #insert "#place g;components: [FIELD_COUNT]FieldType = ---;";
    #if b_location == ._0 then #insert "#place b;components: [FIELD_COUNT]FieldType = ---;";
    #if a_location == ._0 then #insert "#place a;components: [FIELD_COUNT]FieldType = ---;";
}

type_is_pixel :: ($T : Type) -> bool {
    info := type_info(T);
    if info.type != .STRUCT return false;
    struct_info := cast(*Type_Info_Struct)info;
    return String.compare(struct_info.name, "UniformPixel") == 0 || String.compare(struct_info.name, "MaskedPixel") == 0;
}

ToGreyAlgorithm :: enum {
    CCIR601;
    AVERAGE;
}

convert_pixel_field :: inline (
    p: $InPxType/interface PixelBase, 
    $in_field: PixelField, 
    $OutPxType: Type,
    $out_field: PixelField,
    $normalize_when_upconvert := true
) -> OutPxType.FieldType {
    #run assert(type_is_pixel(InPxType));
    #run assert(type_is_pixel(OutPxType));
    InFieldType :: #run InPxType.FieldType;
    OutFieldType :: #run OutPxType.FieldType;
    IN_PIXEL_IS_MASKED :: #run InPxType.IS_MASKED; // else uniform
    OUT_PIXEL_IS_MASKED :: #run OutPxType.IS_MASKED;
    IN_PIXEL_FIELD_IS_INT :: #run type_info(InFieldType).type != .FLOAT;
    OUT_PIXEL_FIELD_IS_INT :: #run type_info(OutFieldType).type != .FLOAT;

    IN_TOTAL_BITS :: #run size_of(InFieldType) * 8;
    OUT_TOTAL_BITS :: #run size_of(OutFieldType) * 8;
    IN_ACTIVE_BITS :: #ifx IN_PIXEL_IS_MASKED 
        then #run p.BIT_WIDTHS[xx in_field] 
        else #ifx #run in_field == .R && !InPxType.HAS_R then 0
        else #ifx #run in_field == .G && !InPxType.HAS_G then 0
        else #ifx #run in_field == .B && !InPxType.HAS_B then 0
        else #ifx #run in_field == .A && !InPxType.HAS_A then 0
        else IN_TOTAL_BITS;
    OUT_ACTIVE_BITS :: #ifx OUT_PIXEL_IS_MASKED 
        then #run OutPxType.BIT_WIDTHS[xx out_field] 
        else #ifx #run out_field == .R && !OutPxType.HAS_R then 0
        else #ifx #run out_field == .G && !OutPxType.HAS_G then 0
        else #ifx #run out_field == .B && !OutPxType.HAS_B then 0
        else #ifx #run out_field == .A && !OutPxType.HAS_A then 0
        else OUT_TOTAL_BITS;

    IN_MASK : u32 : xx #ifx IN_PIXEL_IS_MASKED then #run p.MASKS[xx in_field] else 0;
    OUT_MASK : u32 : xx #ifx OUT_PIXEL_IS_MASKED then #run OutPxType.MASKS[xx out_field] else 0;
    IN_TRAILING_ZEROES :: #ifx IN_PIXEL_IS_MASKED then #run p.TRAILING_ZEROES[xx in_field] else 0;
    OUT_TRAILING_ZEROES :: #ifx OUT_PIXEL_IS_MASKED then #run OutPxType.TRAILING_ZEROES[xx out_field] else 0;

    IN_ACTIVE_MAX : float64 : 
        #ifx IN_PIXEL_IS_MASKED then #run cast(float64) (IN_MASK >> IN_TRAILING_ZEROES) 
        else #ifx IN_PIXEL_FIELD_IS_INT then cast(float64) (~(cast(InFieldType)0))
        else cast(float64) 1.0;
    IN_ACTIVE_INV_MAX : float64 : #ifx #run IN_ACTIVE_MAX == 0 
        then cast(float64) 0 
        else #run 1.0 / cast(float64) IN_ACTIVE_MAX;
    OUT_ACTIVE_MAX_OUT_TYPE : OutFieldType : 
        #ifx OUT_PIXEL_IS_MASKED then #run cast(OutFieldType) (OUT_MASK >> OUT_TRAILING_ZEROES) 
        else #ifx OUT_PIXEL_FIELD_IS_INT then (~(cast(OutFieldType)0))
        else cast(OutFieldType) 1.0;
    OUT_ACTIVE_MAX : float64 : xx OUT_ACTIVE_MAX_OUT_TYPE;
    OUT_ACTIVE_INV_MAX : float64 : #ifx #run OUT_ACTIVE_MAX == 0 
        then cast(float64) 0 
        else #run 1.0 / cast(float64) OUT_ACTIVE_MAX;
    OUT_BITS_GREATER :: OUT_ACTIVE_BITS > IN_ACTIVE_BITS;

    IN_HEAD :: #ifx IN_PIXEL_IS_MASKED then IN_ACTIVE_BITS + IN_TRAILING_ZEROES else IN_ACTIVE_BITS;
    OUT_HEAD :: #ifx OUT_PIXEL_IS_MASKED then OUT_ACTIVE_BITS + OUT_TRAILING_ZEROES else OUT_ACTIVE_BITS;
    OUT_SHIFT_DIFF :: OUT_HEAD - IN_HEAD;
    ABS_OUT_SHIFT :: #run #ifx OUT_SHIFT_DIFF < 0 then -OUT_SHIFT_DIFF else OUT_SHIFT_DIFF;

    // for whatever reason, sometimes the compiler complains about indexing with a negative value along prunable/unused
    // code paths. here we get index, possibly -1 for nonexistent field, and convert -1 to 0 so the compiler
    // doesn't have a fit.
    IN_INDEX_COMPTIME_UNSAFE ::
        #ifx #run in_field == .R then InPxType.R_INDEX
        else #ifx #run in_field == .G then InPxType.G_INDEX
        else #ifx #run in_field == .B then InPxType.B_INDEX
        else #ifx #run in_field == .A then InPxType.A_INDEX
        else -1;
    IN_FIELD_INDEX : s8 : #ifx IN_INDEX_COMPTIME_UNSAFE == -1 then 0 else IN_INDEX_COMPTIME_UNSAFE;

    #if IN_ACTIVE_BITS == 0 {
        #if OUT_ACTIVE_BITS != 0 && out_field == .A {
            return OUT_ACTIVE_MAX_OUT_TYPE;
        } else {
            return 0;
        }
    } else #if OUT_ACTIVE_BITS == 0 {
        return 0;
    }

    // when upconverting int fields, an intermediate normalized float64 conversion can be done. doing a normalized
    // conversion dramatically increases the quality of the results. using float64 avoids needing to clamp due
    // to precision issues.
    #if IN_PIXEL_FIELD_IS_INT {
        #if OUT_PIXEL_FIELD_IS_INT {
            #if IN_PIXEL_IS_MASKED {
                #if OUT_PIXEL_IS_MASKED {
                    // masked int -> masked int
                    #if OUT_BITS_GREATER && normalize_when_upconvert {
                        unmasked_flt : float64 = xx ((p.c & IN_MASK) >> IN_TRAILING_ZEROES);
                        normalized := unmasked_flt * IN_ACTIVE_INV_MAX;
                        scaled : OutFieldType = xx (normalized * OUT_ACTIVE_MAX);
                        return scaled << OUT_TRAILING_ZEROES;
                    } else #if OUT_SHIFT_DIFF == 0 {
                        return xx (((cast(u32) p.c) & IN_MASK) & OUT_MASK);
                    } else #if OUT_SHIFT_DIFF > 0 {
                        return xx ((((cast(u32) p.c) & IN_MASK) << ABS_OUT_SHIFT) & OUT_MASK);
                    } else {
                        return xx ((((cast(u32) p.c) & IN_MASK) >> ABS_OUT_SHIFT) & OUT_MASK);
                    }
                } else {
                    // masked int -> unmasked int
                    #if OUT_BITS_GREATER && normalize_when_upconvert {
                        unmasked_flt : float64 = xx ((p.c & IN_MASK) >> IN_TRAILING_ZEROES);
                        normalized := unmasked_flt * IN_ACTIVE_INV_MAX;
                        return xx (normalized * OUT_ACTIVE_MAX);
                    } else #if OUT_SHIFT_DIFF == 0 {
                        return xx ((cast(u32) p.c) & IN_MASK);
                    } else #if OUT_SHIFT_DIFF > 0 {
                        return xx (((cast(u32) p.c) & IN_MASK) << ABS_OUT_SHIFT);
                    } else {
                        return xx (((cast(u32) p.c) & IN_MASK) >> ABS_OUT_SHIFT);
                    }
                }
            } else {
                #if OUT_PIXEL_IS_MASKED {
                    // unmasked int -> masked int
                    #if OUT_BITS_GREATER && normalize_when_upconvert {
                        flt : float64 = xx p.components[IN_FIELD_INDEX];
                        normalized := flt * IN_ACTIVE_INV_MAX;
                        scaled : OutFieldType = xx (normalized * OUT_ACTIVE_MAX);
                        return scaled << OUT_TRAILING_ZEROES;
                    } else #if OUT_SHIFT_DIFF == 0 {
                        return xx ((cast(u32) p.components[IN_FIELD_INDEX]) & OUT_MASK);
                    } else #if OUT_SHIFT_DIFF > 0 {
                        return xx (((cast(u32) p.components[IN_FIELD_INDEX]) << ABS_OUT_SHIFT) & OUT_MASK);
                    } else {
                        return xx (((cast(u32) p.components[IN_FIELD_INDEX]) >> ABS_OUT_SHIFT) & OUT_MASK);
                    }
                } else {
                    // unmasked int -> unmasked int
                    #if OUT_BITS_GREATER && normalize_when_upconvert {
                        flt : float64 = xx p.components[IN_FIELD_INDEX];
                        normalized := flt * IN_ACTIVE_INV_MAX;
                        return xx (normalized * OUT_ACTIVE_MAX);
                    } else #if OUT_SHIFT_DIFF == 0 {
                        return xx p.components[IN_FIELD_INDEX];
                    } else #if OUT_SHIFT_DIFF > 0 {
                        return xx ((cast(u32) p.components[IN_FIELD_INDEX]) << ABS_OUT_SHIFT);
                    } else {
                        return xx ((cast(u32) p.components[IN_FIELD_INDEX]) >> ABS_OUT_SHIFT);
                    }
                }
            }
        } else {
             #if IN_PIXEL_IS_MASKED {
                // masked int -> float
                unmasked_flt : float64 = xx ((p.c & IN_MASK) >> IN_TRAILING_ZEROES);
                return xx (unmasked_flt * IN_ACTIVE_INV_MAX);
            } else {
                // unmasked int -> float
                flt : float64 = xx p.components[IN_FIELD_INDEX];
                return xx (flt * IN_ACTIVE_INV_MAX);
            }
        }
    } else {
        #if OUT_PIXEL_FIELD_IS_INT {
            #if OUT_PIXEL_IS_MASKED {
                // float -> masked int
                dbl : float64 = xx p.components[IN_FIELD_INDEX];
                #if OUT_TRAILING_ZEROES > 0 {
                    return (cast(OutFieldType) (dbl * OUT_ACTIVE_MAX)) << OUT_TRAILING_ZEROES;
                } else {
                    return xx (dbl * OUT_ACTIVE_MAX);
                }
            } else {
                // float -> unmasked int
                dbl : float64 = xx p.components[IN_FIELD_INDEX];
                return xx (dbl * OUT_ACTIVE_MAX);
            }
        } else {
            // float -> float
            return p.components[IN_FIELD_INDEX];
        }
    }
}

pixel_has_field :: ($InPxType: Type, field: PixelField) -> bool {
    if field == .R then return InPxType.HAS_R;
    else if field == .G then return InPxType.HAS_G;
    else if field == .B then return InPxType.HAS_B;
    else return InPxType.HAS_A;
}

set_pixel_field :: inline (p: *$InPxType/interface PixelBase, $field: PixelField, value: float32) {
    #if #run !pixel_has_field(InPxType, field) then return;
    normval_ptr := cast(*R32f) *value;
    set_pixel_field_exact(p, field, convert_pixel_field(<<normval_ptr, .R, InPxType, field));
}

set_pixel_field :: inline (p: *$InPxType/interface PixelBase, $field: PixelField, value: u8) {
    #if #run !pixel_has_field(InPxType, field) then return;
    normval_ptr := cast(*R8) *value;
    set_pixel_field_exact(p, field, convert_pixel_field(<<normval_ptr, .R, InPxType, field));
}

set_pixel :: inline (p: *$InPxType/interface PixelBase, values: *Color4f) {
    rgba32f := force_cast(values, RGBA32f);
    <<p = convert_pixel(rgba32f, InPxType);
}

set_pixel :: inline (p: *$InPxType/interface PixelBase, values: Color4f) {
    rgba32f := force_cast(*values, RGBA32f);
    <<p = convert_pixel(rgba32f, InPxType);
}

set_pixel :: inline (p: *$InPxType/interface PixelBase, values: *Color4b) {
    rgba8 := force_cast(values, RGBA8);
    <<p = convert_pixel(rgba8, InPxType);
}

set_pixel :: inline (p: *$InPxType/interface PixelBase, values: Color4b) {
    rgba8 := force_cast(*values, RGBA8);
    <<p = convert_pixel(rgba8, InPxType);
}

set_pixel_field_exact :: inline (
    p: *$InPxType/interface PixelBase, $field: PixelField, value: InPxType.FieldType, $clear_masked_field := true
) {
    #if #run !pixel_has_field(InPxType, field) then return;
    #if p.IS_UNIFORM {
        field_index := #run uniform_field_index(field, InPxType);
        p.components[field_index] = value;
    } else {
        // if the whole pixel is getting set at once, then we don't need to clear the field every time
        #if clear_masked_field {
            p.c = (p.c & ~p.MASKS[xx field]) | value;
        } else {
            p.c |= value;
        }
    }
}

convert_pixel :: inline (
    p: $InPxType/interface PixelBase, 
    $OutPxType: Type, 
    $normalize_when_upconvert := true, 
    $to_grey := ToGreyAlgorithm.CCIR601
) -> OutPxType {
    #run assert(type_is_pixel(InPxType) && type_is_pixel(OutPxType));

    COLOR_TO_COLOR :: #run !p.IS_GREY && !OutPxType.IS_GREY;
    COLOR_TO_GREY :: #run !p.IS_GREY && OutPxType.IS_GREY;
    GREY_TO_COLOR :: #run p.IS_GREY && !OutPxType.IS_GREY;
    GREY_TO_GREY :: #run p.IS_GREY && OutPxType.IS_GREY;
    INV_IN_COLOR_FIELD_COUNT :: 
        cast(float64) 1.0 / cast(float64) (cast(u8) p.HAS_R + cast(u8) p.HAS_G + cast(u8) p.HAS_B);

    CCIR601_R : float64 : 0.299;
    CCIR601_G : float64 : 0.587;
    CCIR601_B : float64 : 0.114;

    out_pixel : OutPxType = ---;
    #if #run OutPxType.IS_MASKED then out_pixel.c = 0;

    #if COLOR_TO_COLOR {
        set_pixel_field_exact(*out_pixel, .R, convert_pixel_field(p, .R, OutPxType, .R, normalize_when_upconvert), false);
        set_pixel_field_exact(*out_pixel, .G, convert_pixel_field(p, .G, OutPxType, .G, normalize_when_upconvert), false);
        set_pixel_field_exact(*out_pixel, .B, convert_pixel_field(p, .B, OutPxType, .B, normalize_when_upconvert), false);
        set_pixel_field_exact(*out_pixel, .A, convert_pixel_field(p, .A, OutPxType, .A, normalize_when_upconvert), false);
    } else #if COLOR_TO_GREY {
        norm_r := convert_pixel_field(p, .R, R64f, .R, normalize_when_upconvert);
        norm_g := convert_pixel_field(p, .G, R64f, .R, normalize_when_upconvert);
        norm_b := convert_pixel_field(p, .B, R64f, .R, normalize_when_upconvert);
        r : R64f = ---;
        #if #complete to_grey == {
        case .AVERAGE;
            r.r = (norm_r + norm_g + norm_b) * INV_IN_COLOR_FIELD_COUNT;
        case .CCIR601;
            r.r = norm_r * CCIR601_R + norm_g * CCIR601_G + norm_b * CCIR601_B;
        }
        set_pixel_field_exact(*out_pixel, .R, convert_pixel_field(r, .R, OutPxType, .R, normalize_when_upconvert), false);
        set_pixel_field_exact(*out_pixel, .A, convert_pixel_field(p, .A, OutPxType, .A, normalize_when_upconvert), false);
    } else #if GREY_TO_COLOR {
        set_pixel_field_exact(*out_pixel, .R, convert_pixel_field(p, .R, OutPxType, .R, normalize_when_upconvert), false);
        set_pixel_field_exact(*out_pixel, .G, convert_pixel_field(p, .R, OutPxType, .G, normalize_when_upconvert), false);
        set_pixel_field_exact(*out_pixel, .B, convert_pixel_field(p, .R, OutPxType, .B, normalize_when_upconvert), false);
        set_pixel_field_exact(*out_pixel, .A, convert_pixel_field(p, .A, OutPxType, .A, normalize_when_upconvert), false);
    } else { // GREY_TO_GREY
        set_pixel_field_exact(*out_pixel, .R, convert_pixel_field(p, .R, OutPxType, .R, normalize_when_upconvert), false);
        set_pixel_field_exact(*out_pixel, .A, convert_pixel_field(p, .A, OutPxType, .A, normalize_when_upconvert), false);
    }
    return out_pixel;
}

// TODO: temp alloc
// format_pixel :: (p: $InPxType/interface PixelBase) -> string {
    // #run assert(type_is_pixel(InPxType));
    // #if InPxType.IS_UNIFORM {
        // builder : String_Builder;
        // info := cast(*Type_Info_Struct) type_info(InPxType);
        // print_to_builder(*builder, "(");
        // for i : 0..InPxType.FIELD_COUNT-1 {
            // member := *info.members[i];
            // if i == InPxType.FIELD_COUNT - 1
                // then print_to_builder(*builder, "%: %", member.name, p.components[i]);
                // else print_to_builder(*builder, "%: %, ", member.name, p.components[i]);
        // }
        // print_to_builder(*builder, ")");
        // return builder_to_string(*builder);
    // } else {
    // }
// }
