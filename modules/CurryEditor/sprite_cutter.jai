
SpriteCutInfo :: struct {
    image_rect : PointRectTD;
    image_padded_rect : PointRectTD;
    sprite_padding_offsets : [2]IntVector2;
    sprite_padded_dimensions : IntVector2;
    sprite_padded_step : IntVector2;
    sprite_grid_dimensions : IntVector2;
    sprite_count : s32;
}

SpriteCutter_Transient :: struct {
    draw_cut_info : SpriteCutInfo;
    total_image_translation: Vector2;
    total_preview_translation: Vector2;
    recreate_preview : bool;
}

SpriteCutter :: struct {
    using #as common: EditorUtilityCommon;
    using transient_data: *SpriteCutter_Transient;

    image_for_cut : Sprite; 
    sprite_preview : Sprite;
    loaded_image_counter : s32;

    sprite_width : s32 = 64;
    sprite_height : s32 = 64;

    // left/right & top/bottoms are locked together by default.
    // --- padding around every individual sprite frame ---
    sprite_x_padding_unlocked : bool;
    sprite_y_padding_unlocked : bool;
    image_x_padding_unlocked : bool;
    image_y_padding_unlocked : bool;
    sprite_x_padding_left : s32;
    sprite_x_padding_right : s32;
    sprite_y_padding_top : s32;
    sprite_y_padding_bottom : s32;

    // --- padding along the edge of the image containing the sprite frames ---
    image_x_padding_left : s32;
    image_x_padding_right : s32;
    image_y_padding_top : s32;
    image_y_padding_bottom : s32;

    sprite_frame_start : s32;
    sprite_frame_count : s32 = 1;
    sprite_frame_rate : s32 = 12;
    sprite_anim_reverse : bool;
    sprite_anim_hflip : bool;
    sprite_anim_vflip : bool;
    sprite_anim_loop := true;
    sprite_pause : bool;
    sprite_keep_cpu_data : bool;

    mouse_drag_delta := Vector2.{};
    mouse_inside_viewport : s32 = -1;
    mouse_drag_started_in_viewport : s32 = -1;

    image_camera_translation := Vector2.{};
    preview_camera_translation := Vector2.{};
    image_camera_scale := 1.0;
    preview_camera_scale := 1.0;

    set_layout_once : bool;

    texture_creation_info := TextureCreationInfo.{
        delete_local=false,
        filter_minification = #run filter_string_to_settings("Nearest"),
        filter_magnification = #run filter_string_to_settings("Nearest")
    };

}

get_sprite_cut_info :: (using cut_info: *SpriteCutInfo, cutter: *SpriteCutter, centered := false) {
    image_tex := *cutter.image_for_cut.texture;
    tex_width_is_odd := (image_tex.width & 1) != 0;
    tex_height_is_odd := (image_tex.height & 1) != 0;
    tex_half_dims := IntVector2.{ image_tex.width / 2, image_tex.height / 2 };
    tex_half_dims_odd_corrected := IntVector2.{
        tex_half_dims.x + xx (ifx tex_width_is_odd then 1 else 0),
        tex_half_dims.y + xx (ifx tex_height_is_odd then 1 else 0),
    };

    if centered {
        image_rect.upper_left = .{-tex_half_dims.x, tex_half_dims.y};
        image_rect.lower_right = .{tex_half_dims_odd_corrected.x, -tex_half_dims_odd_corrected.y};
    } else {
        image_rect.upper_left = .{0, image_tex.height};
        image_rect.lower_right = .{image_tex.width, 0};
    }

    image_padded_rect.upper_left = 
        image_rect.upper_left + .{cutter.image_x_padding_left, -cutter.image_y_padding_top};
    image_padded_rect.lower_right = 
        image_rect.lower_right - .{cutter.image_x_padding_right, -cutter.image_y_padding_bottom};

    sprite_padding_offsets[0] = .{cutter.sprite_x_padding_left, -cutter.sprite_y_padding_top};
    sprite_padding_offsets[1] = .{-cutter.sprite_x_padding_right, cutter.sprite_y_padding_bottom};

    sprite_padded_dimensions = .{cutter.sprite_width, cutter.sprite_height};
    sprite_padded_step = .{cutter.sprite_width, -cutter.sprite_height};
    image_padded_dimensions := IntVector2.{
        image_padded_rect.lower_right.x - image_padded_rect.upper_left.x,
        image_padded_rect.upper_left.y - image_padded_rect.lower_right.y
    };
    if sprite_padded_dimensions.x == 0 || sprite_padded_dimensions.y == 0 {
        sprite_grid_dimensions = .{0, 0};
        sprite_count = 0;
    } else {
        sprite_grid_dimensions = image_padded_dimensions / sprite_padded_dimensions;
        sprite_count = sprite_grid_dimensions.x * sprite_grid_dimensions.y;
    }
}

sprite_cutter_menu :: (using cutter: *SpriteCutter) {
    recreate_preview = false;

    INDENT :: 10.0;
    if ImGui.CollapsingHeader("Image / Load Settings", ImGui.TreeNodeFlags.DefaultOpen) {
        defer ImGui.Text("");
        {
            ImGui.PushItemWidth(100.0);
            defer ImGui.PopItemWidth();

            minification_index := filter_setting_to_index(texture_creation_info.filter_minification);
            magnification_index := filter_setting_to_index(texture_creation_info.filter_magnification);

            if ImGui.BeginCombo("filtering: minification", temp_c_string(tex_filter_style_strings[minification_index])) {
                defer ImGui.EndCombo();
                for tex_filter_style_strings {
                    if ImGui.Selectable(temp_c_string(it), false, .None) {
                        minification_index = it_index;
                    }
                    if minification_index == it_index {
                        ImGui.SetItemDefaultFocus();
                    }
                }
            }
            if ImGui.BeginCombo("filtering: magnification", temp_c_string(tex_filter_style_strings[magnification_index])) {
                defer ImGui.EndCombo();
                for tex_filter_style_strings {
                    if ImGui.Selectable(temp_c_string(it), false, .None) {
                        magnification_index = it_index;
                    }
                    if magnification_index == it_index {
                        ImGui.SetItemDefaultFocus();
                    }
                }
            }

            texture_creation_info.filter_minification = filter_index_to_setting(minification_index);
            texture_creation_info.filter_magnification = filter_index_to_setting(magnification_index);
        }

        if ImGui.Button("load image") {
            image, success := open_file_dialog(Image);
            if success {
                clean_up_resources(cutter);
                image_for_cut_tex := texture_create(image, texture_creation_info);
                image_for_cut = sprite_create(*image_for_cut_tex);
                log("loaded image %", image_for_cut.texture.image.asset_path);
                loaded_image_counter += 1;
                recreate_preview = image_for_cut.texture.render_id != 0;
            } else {
                log("unable to load image");
            }
        } else if ImGui.Button("load sprite") {
            sprite, success := open_file_dialog(Sprite);
            if success {
                clean_up_resources(cutter);
                image_for_cut = sprite_create(*sprite.texture);
                // image_for_cut.texture.image.asset_path = sprite.texture.image.asset_path;
                log("loaded sprite %", image_for_cut.texture.image.asset_path);
                loaded_image_counter += 1;
                recreate_preview = image_for_cut.texture.render_id != 0;
                if !set_layout_once then layout = .DUET_LEFT_RIGHT;
            }
        }
        if loaded_image_counter > 0 && ImGui.Button("reload") {
            if image_for_cut.texture.image.format == .SPRITE_ANIMATION {
                sprite := sprite_load(image_for_cut.texture.image.asset_path);
                clean_up_resources(cutter);
                image_for_cut = sprite_create(*sprite.texture);
                log("loaded sprite %", image_for_cut.texture.image.asset_path);
            } else {
                image := image_create(image_for_cut.texture.image.asset_path);
                clean_up_resources(cutter);
                image_for_cut_tex := texture_create(image, texture_creation_info);
                image_for_cut = sprite_create(*image_for_cut_tex);
                log("loaded image %", image_for_cut.texture.image.asset_path);
            }
            loaded_image_counter += 1;
            recreate_preview = image_for_cut.texture.render_id != 0;
        }
    }

    if image_for_cut.texture.render_id == 0 then return;

    sprite_width = min(sprite_width, image_for_cut.texture.width);
    sprite_height = min(sprite_height, image_for_cut.texture.height);

    if ImGui.CollapsingHeader("Preview", ImGui.TreeNodeFlags.DefaultOpen)
    {
        defer ImGui.Text("");
        ImGui.PushItemWidth(80.0);
        defer ImGui.PopItemWidth();

        ImGui.SliderFloat("view proportion", *layout_proportion, 0.0, 1.0);

        {
            ImGui.PushItemWidth(100.0);
            defer ImGui.PopItemWidth();
            viewtype_strings := string.["left/right", "top/bottom"];
            viewtype_index: s64;
            if layout == {
            case .DUET_LEFT_RIGHT; viewtype_index = 0;
            case .DUET_TOP_BOTTOM; viewtype_index = 1;
            }

            if ImGui.BeginCombo("view split", temp_c_string(viewtype_strings[viewtype_index])) {
                defer ImGui.EndCombo();
                for viewtype_strings {
                    if ImGui.Selectable(temp_c_string(it), false, .None) {
                        set_layout_once = true;
                        viewtype_index = it_index;
                    }
                    if viewtype_index == it_index {
                        ImGui.SetItemDefaultFocus();
                    }
                }
            }

            if viewtype_index == {
            case 0; layout = .DUET_LEFT_RIGHT; 
            case 1; layout = .DUET_TOP_BOTTOM;
            }
        }

        ImGui.SeparatorText("Scale & Translation");

        ImGui.InputFloat("image scale", *image_camera_scale, 0.1, 1.0, "%.1f");
        ImGui.InputFloat("preview scale", *preview_camera_scale, 0.1, 1.0, "%.1f");
        if ImGui.Button("reset translations") {
            image_camera_translation = .{};
            preview_camera_translation = .{};
        }
        ImGui.InputFloat("zoom speed override", *zoom_speed_override, 1.0, 10.0, "%.f");
        ImGui.SameLine();
        if ImGui.Button("disable") then zoom_speed_override = 0.0;

        ImGui.SeparatorText("Animation Stepping");

        ImGui.Checkbox("Pause Animation", *sprite_pause);
        if sprite_pause {
            sprite_preview.frame_paused = true;
            ImGui.Indent(INDENT);
            defer ImGui.Unindent(INDENT);
            ImGui.InputInt("Step", *sprite_preview.frame_index);
            if sprite_preview.frame_index < 0 then sprite_preview.frame_index = sprite_preview.frame_count - 1;
            else if sprite_preview.frame_index >= sprite_preview.frame_count then sprite_preview.frame_index = 0;
        }
        else sprite_preview.frame_paused = false;
    }

    if ImGui.CollapsingHeader("Cut Sprite", ImGui.TreeNodeFlags.DefaultOpen)
    {
        defer ImGui.Text("");
        ImGui.PushItemWidth(80.0);
        defer ImGui.PopItemWidth();

        clamp_opposing_padding :: inline (side_a: *s32, side_b: *s32, total_resource: s32) {
            <<side_a = clamp(<<side_a, 0, total_resource);
            remain := total_resource - <<side_a;
            <<side_b = clamp(<<side_b, 0, remain);
        }
        
        recreate_preview |= ImGui.InputInt("width", *sprite_width);
        recreate_preview |= ImGui.InputInt("height", *sprite_height);

        ImGui.SeparatorText("Animation");
        
        recreate_preview |= ImGui.InputInt("frame start", *sprite_frame_start);
        recreate_preview |= ImGui.InputInt("frame count", *sprite_frame_count);
        recreate_preview |= ImGui.InputInt("frame rate", *sprite_frame_rate);
        recreate_preview |= ImGui.Checkbox("save as looping", *sprite_anim_loop); 
        recreate_preview |= ImGui.Checkbox("reverse", *sprite_anim_reverse);
        recreate_preview |= ImGui.Checkbox("vertical flip", *sprite_anim_vflip);
        recreate_preview |= ImGui.Checkbox("horizontal flip", *sprite_anim_hflip);

        ImGui.SeparatorText("Image Padding");

        if image_x_padding_unlocked {
            recreate_preview |= ImGui.InputInt("x left##ImagePadding", *image_x_padding_left);
            ImGui.SameLine();
            ImGui.Checkbox("unlock##ImagePaddingX", *image_x_padding_unlocked);
            recreate_preview |= ImGui.InputInt("x right##ImagePadding", *image_x_padding_right);
        } else {
            recreate_preview |= ImGui.InputInt("x##ImagePadding", *image_x_padding_left);
            ImGui.SameLine();
            ImGui.Checkbox("unlock##ImagePaddingX", *image_x_padding_unlocked);
            image_x_padding_right = image_x_padding_left;
        }
        if image_y_padding_unlocked {
            recreate_preview |= ImGui.InputInt("y top##ImagePadding", *image_y_padding_top);
            ImGui.SameLine();
            ImGui.Checkbox("unlock##ImagePaddingY", *image_y_padding_unlocked);
            recreate_preview |= ImGui.InputInt("y bottom##ImagePadding", *image_y_padding_bottom);
        } else {
            recreate_preview |= ImGui.InputInt("y##ImagePadding", *image_y_padding_top);
            ImGui.SameLine();
            ImGui.Checkbox("unlock##ImagePaddingY", *image_y_padding_unlocked);
            image_y_padding_bottom = image_y_padding_top;
        }

        clamp_opposing_padding(*image_x_padding_left, *image_x_padding_right, image_for_cut.texture.width);
        clamp_opposing_padding(*image_y_padding_top, *image_y_padding_bottom, image_for_cut.texture.height);

        ImGui.SeparatorText("Sprite Padding");

        if sprite_x_padding_unlocked {
            recreate_preview |= ImGui.InputInt("x left##SpritePadding", *sprite_x_padding_left);
            ImGui.SameLine();
            ImGui.Checkbox("unlock##SpritePaddingX", *sprite_x_padding_unlocked);
            recreate_preview |= ImGui.InputInt("x right##SpritePadding", *sprite_x_padding_right);
        } else {
            recreate_preview |= ImGui.InputInt("x##SpritePadding", *sprite_x_padding_left);
            ImGui.SameLine();
            ImGui.Checkbox("unlock##SpritePaddingX", *sprite_x_padding_unlocked);
            sprite_x_padding_right = sprite_x_padding_left;
        }
        if sprite_y_padding_unlocked {
            recreate_preview |= ImGui.InputInt("y top##SpritePadding", *sprite_y_padding_top);
            ImGui.SameLine();
            ImGui.Checkbox("unlock##SpritePaddingY", *sprite_y_padding_unlocked);
            recreate_preview |= ImGui.InputInt("y bottom##SpritePadding", *sprite_y_padding_bottom);
        } else {
            recreate_preview |= ImGui.InputInt("y##SpritePadding", *sprite_y_padding_top);
            ImGui.SameLine();
            ImGui.Checkbox("unlock##SpritePaddingY", *sprite_y_padding_unlocked);
            sprite_y_padding_bottom = sprite_y_padding_top;
        }

        ImGui.SeparatorText("");

        ImGui.Checkbox("keep data in RAM on load", *sprite_keep_cpu_data); 

        if ImGui.Button("save sprite") {
            path, success := save_file_dialog(Sprite);
            if success {
                log("saving sprite: %", path);
                sprite_preview.texture.creation_info.delete_local = !sprite_keep_cpu_data;
                sprite_save(*sprite_preview, path);
                sprite_preview.texture.creation_info.delete_local = false;
            }
        }
    }
}

sprite_cutter_update :: (using cutter: *SpriteCutter) {
    if image_for_cut.texture.render_id == 0 return;

    sprite_width = clamp(sprite_width, 1, image_for_cut.texture.width);
    sprite_height = clamp(sprite_height, 1, image_for_cut.texture.height);

    // info for drawing cutter boxes over image (helps with clamping anim params)
    get_sprite_cut_info(*draw_cut_info, cutter, true);

    // --- clamp anim params ---
    sprite_frame_max := draw_cut_info.sprite_count - 1;
    sprite_frame_start = clamp(sprite_frame_start, 0, sprite_frame_max);
    remain_frames := sprite_frame_max - sprite_frame_start + 1;
    sprite_frame_count = clamp(sprite_frame_count, 1, remain_frames);
    sprite_frame_rate = xx max(1, sprite_frame_rate);

    // --- mouse drag/zoom ---
    io := ImGui.GetIO();

    total_image_translation = image_camera_translation;
    total_preview_translation = preview_camera_translation;

    if mouse_drag_started_in_viewport >= 0 && !render_data.resizing_side_bar && !io.WantCaptureMouse {
        if mouse_drag_started_in_viewport == 0 
            then total_image_translation += mouse_drag_delta * (1.0 / image_camera_scale);
            else total_preview_translation += mouse_drag_delta * (1.0 / preview_camera_scale);
        if mouse.left.just_released.fixed_state {
            image_camera_translation = total_image_translation;
            preview_camera_translation = total_preview_translation;
            mouse_drag_started_in_viewport = -1;
            mouse_drag_delta = .{};
        } else {
            mouse_drag_delta = xx ImGui.GetMouseDragDelta();
            mouse_drag_delta.y *= -1.0;
        }
    }

    zoom_speed := ifx zoom_speed_override != 0.0 
        then zoom_speed_override
        else render_data.scroll_zoom_speed;

    if mouse.wheel_value != 0.0 {
        if mouse_inside_viewport == 0 {
            image_camera_scale += image_camera_scale * mouse.wheel_value * zoom_speed * context.curry.delta_time;
        } else if mouse_inside_viewport == 1 {
            preview_camera_scale += preview_camera_scale * mouse.wheel_value * zoom_speed * context.curry.delta_time;
        }
    }

    if !recreate_preview then return;

    if sprite_preview.texture.render_id != 0 {
        sprite_delete(*sprite_preview);
    }

    // --- create sprite preview ---
    preview_cut_info: SpriteCutInfo = ---;
    get_sprite_cut_info(*preview_cut_info, cutter, false);

    preview_frame_width := sprite_width - (sprite_x_padding_left + sprite_x_padding_right);
    preview_frame_height := sprite_height - (sprite_y_padding_top + sprite_y_padding_bottom);

    preview_image_width := preview_frame_width;
    preview_image_height := preview_frame_height * sprite_frame_count;

    if preview_frame_width <= 0
        || preview_frame_height <= 0
        || preview_image_height <= 0
        || preview_cut_info.sprite_grid_dimensions.x == 0
    {
        log("unable to create sprite preview. invalid width, height and/or padding.");
        return;
    }

    sprite_frame_end := sprite_frame_start + (sprite_frame_count - 1);

    preview_image := image_create(preview_image_width, preview_image_height, .SPRITE_ANIMATION);
    frame_pixel_count := preview_frame_width * preview_frame_height;

    copy_frame :: (f: s32) #expand {
        pivot_y := f / preview_cut_info.sprite_grid_dimensions.x;
        pivot_x := f - pivot_y * preview_cut_info.sprite_grid_dimensions.x;
        padded_rect: PointRectTD;
        padded_rect.upper_left = 
            preview_cut_info.image_padded_rect.upper_left 
            + (preview_cut_info.sprite_padded_step * IntVector2.{pivot_x, pivot_y});
        padded_rect.lower_right = padded_rect.upper_left + preview_cut_info.sprite_padded_step;
        sprite_rect_td := PointRectTD.{
            padded_rect.upper_left + preview_cut_info.sprite_padding_offsets[0],
            padded_rect.lower_right + preview_cut_info.sprite_padding_offsets[1]
        };

        sprite_rect := make_rect_bu(sprite_rect_td);
        upper_y_bound := sprite_rect.upper_right.y - 1;

        y: s32 = ---;
        y_increment: s32 = ---;

        if sprite_anim_vflip {
            y = upper_y_bound;
            y_increment = -1;
        } else {
            y = sprite_rect.lower_left.y;
            y_increment  = 1;
        }

        p := out_frame_placement * (preview_frame_width * preview_frame_height);

        for y_counter : sprite_rect.lower_left.y..upper_y_bound {
            if sprite_anim_hflip
            then for < x : sprite_rect.upper_right.x-1..sprite_rect.lower_left.x {
                out_pixels[p] = in_pixels[y * image_for_cut.texture.width + x];
                p += 1;
            } else {
                memcpy(
                    *out_pixels[p], 
                    *in_pixels[y * image_for_cut.texture.width + sprite_rect.lower_left.x], 
                    size_of(RGBA8) * preview_frame_width
                );
                p += preview_frame_width;
            }
            y += y_increment;
        }
        out_frame_placement -= 1;
    }

    // sprite frames stored top to bottom
    out_frame_placement := sprite_frame_count - 1;
    in_pixels := cast(*RGBA8)image_for_cut.texture.image.raw_data.data;
    out_pixels := cast(*RGBA8)preview_image.raw_data.data;

    if sprite_anim_reverse
    then for < i : sprite_frame_end..sprite_frame_start {
        copy_frame(i);
    } else for i : sprite_frame_start..sprite_frame_end {
        copy_frame(i);
    }

    preview_texture := texture_create(preview_image, texture_creation_info);
    sprite_preview = sprite_create(
        *preview_texture, SpriteHeader.{xx sprite_frame_rate, xx sprite_frame_count, 1.0, sprite_anim_loop}
    );
}

sprite_cutter_present_graphics :: (using cutter: *SpriteCutter) {
    if image_for_cut.texture.render_id == 0 return;

    // TODO: need to offset the image if it has an odd number of pixels in a dimension

    draw_in_viewport :: (index: s32, camera_translation: Vector3, camera_scale: float32) #expand {
        offset_proportion := ifx index == 0 then 1.0 - layout_proportion else layout_proportion;
        if layout == .DUET_TOP_BOTTOM {
            if index == 0 
                then push_viewport(.{offset_bottom.proportion=offset_proportion}, true);
                else push_viewport(.{offset_top.proportion=offset_proportion}, true);
        } else {
            if index == 0
                then push_viewport(.{offset_right.proportion=offset_proportion}, true);
                else push_viewport(.{offset_left.proportion=offset_proportion}, true);
        }
        do_standard_viewport_highlight();
        defer pop_viewport();

        camera := camera_create(.ORTHOGRAPHIC, ._2D, ViewSettingsOrthographic.{scale=camera_scale});

        viewport := last_cached_viewport_rect();
        camera_vp := viewport_view_projection_matrix(camera, viewport); 
        set_viewport_for_draw(viewport);

        use_preview := ifx index == 0 then *image_for_cut else *sprite_preview;
        sprite_draw(use_preview, camera_translation, *camera_vp);

        rect_td := make_rect_td(viewport);
        if point_inside_rect(rect_td, render_data.top_down_mouse_pos) {
            if mouse.left.just_pressed.fixed_state then mouse_drag_started_in_viewport = index;
            mouse_inside_viewport = index;
        }
    }

    mouse_inside_viewport = -1;
    sprite_animate(*sprite_preview, context.curry.delta_time);
    draw_in_viewport(0, make_vector3(total_image_translation), image_camera_scale);
    draw_in_viewport(1, make_vector3(total_preview_translation), preview_camera_scale);

    preview_viewport : s32 = xx last_cached_viewport();
    image_viewport := preview_viewport - 1;
    preview_viewport_rect := last_cached_viewport_rect();
    image_viewport_rect := context.curry.viewport_rects[image_viewport];

    image_viewport_center := Vector2.{
        xx image_viewport_rect.dimensions.x * 0.5, xx image_viewport_rect.dimensions.y * 0.5
    };
    preview_viewport_center := Vector2.{
        xx preview_viewport_rect.dimensions.x * 0.5, xx preview_viewport_rect.dimensions.y * 0.5
    };

    draw_outline_box :: (
        ul: IntVector2, 
        lr: IntVector2, 
        scale: float32, 
        origin_offset: Vector2, 
        color: Color4b, 
        viewport: s32
    ) {
        vecul := make_vector2(ul) * scale + origin_offset;
        veclr := make_vector2(lr) * scale + origin_offset;
        draw_screenspace_box(vecul, veclr, color, 1.0, ._63, false, viewport);
    }

    scaled_image_translation := total_image_translation * image_camera_scale;
    scaled_preview_translation := total_preview_translation * preview_camera_scale;

    corrected_image_viewport_center := image_viewport_center + scaled_image_translation;
    corrected_preview_viewport_center := preview_viewport_center + scaled_preview_translation;

    {
        using draw_cut_info;

        if sprite_grid_dimensions.x != 0
        then for i : sprite_frame_start..sprite_frame_start+(sprite_frame_count-1) {
            y := i / sprite_grid_dimensions.x;
            x := i - y * sprite_grid_dimensions.x;
            padded_rect: PointRectTD;
            padded_rect.upper_left = image_padded_rect.upper_left + sprite_padded_step * IntVector2.{x, y};
            padded_rect.lower_right = padded_rect.upper_left + sprite_padded_step;
            draw_outline_box(
                padded_rect.upper_left, 
                padded_rect.lower_right,
                image_camera_scale,
                corrected_image_viewport_center,
                Color4b.{rgb=COLOR3B_SKY, a=120},
                image_viewport
            );
            rect := PointRectTD.{
                padded_rect.upper_left + sprite_padding_offsets[0],
                padded_rect.lower_right + sprite_padding_offsets[1]
            };
            draw_outline_box(
                rect.upper_left, 
                rect.lower_right,
                image_camera_scale,
                corrected_image_viewport_center,
                Color4b.{rgb=COLOR3B_SKY, a=200},
                image_viewport
            );
        }

        draw_outline_box(
            image_rect.upper_left, 
            image_rect.lower_right, 
            image_camera_scale,
            corrected_image_viewport_center, 
            Color4b.{rgb=COLOR3B_WHITE, a=80}, 
            image_viewport
        );
        draw_outline_box(
            image_padded_rect.upper_left, 
            image_padded_rect.lower_right, 
            image_camera_scale,
            corrected_image_viewport_center, 
            Color4b.{rgb=COLOR3B_WHITE, a=100}, 
            image_viewport
        );
    }
}

