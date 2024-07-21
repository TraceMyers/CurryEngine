
ImageFormat :: enum u8 {
    NONE;
    INFER;
    SPRITE_ANIMATION;
}

Image :: struct {
    width: s32;
    height: s32;
    stbi_channel_count: s32;
    raw_data: string;
    asset_path: string;
    pixel_tag: PixelTag;
    format := ImageFormat.NONE;
    data_allocator := AllocatorTag.NONE;
}

image_create :: (asset_path: string, format := ImageFormat.INFER) -> Image {
    image: Image;
    c_path := temp_c_string(asset_path);
    image.raw_data.data = stbi_load(c_path, *image.width, *image.height, *image.stbi_channel_count, 4);
    assert(image.raw_data.data != null);
    image.raw_data.count = image.width * image.height * size_of(RGBA8);
    image.asset_path = copy_string(asset_path);
    image.pixel_tag = .RGBA8;
    image.format = format;
    image.data_allocator = .STBI;
    return image;
}

image_create :: (width: s32, height: s32, format: ImageFormat) -> Image {
    assert(width > 0 && height > 0);
    image: Image;
    image.width = width;
    image.height = height;
    image.raw_data = alloc_string(width * height * size_of(RGBA8));
    image.pixel_tag = .RGBA8;
    image.format = format;
    image.data_allocator = .DEFAULT;
    return image;
}

image_create :: (data: *u8, width: s32, height: s32, format: ImageFormat, allocator_tag := AllocatorTag.DEFAULT) -> Image {
    assert(width > 0 && height > 0);
    image: Image;
    image.width = width;
    image.height = height;
    image.raw_data = .{width * height * size_of(RGBA8), data};
    image.pixel_tag = .RGBA8;
    image.format = format;
    image.data_allocator = allocator_tag;
    return image;
}

image_delete :: (image: *Image) {
    if image.asset_path.data != null {
        free(image.asset_path);
    }
    image_delete_data(image);
    <<image = .{};
}

image_delete_data :: (image: *Image) {
    if image.raw_data.data != null {
        if image.data_allocator == .DEFAULT {
            free(image.raw_data);
        } else if image.data_allocator == .STBI {
            stbi_image_free(image.raw_data.data);
        }
    }
    image.raw_data = string.{};
    image.data_allocator = .NONE;
}
