
EditorUtilityTag :: enum {
    NONE;
    SPRITE_CUTTER;
    WORLD_VIEW;
}

EditorViewLayout :: enum {
    SOLO;
    DUET_LEFT_RIGHT;
    DUET_TOP_BOTTOM;
}

EditorUtility :: struct {
    tag : EditorUtilityTag = .NONE;
    union {
        sprite_cutter : SpriteCutter = ---;
    }
}

EditorUtilityCommon :: struct {
    layout := EditorViewLayout.SOLO;
    layout_proportion := 0.5;
    view_scale := 1.0;
    zoom_speed_override := 0.0;
}

EditorUtility_Transient :: union {
    sprite_cutter_transient : SpriteCutter_Transient = ---;
}


WorldViewUtility :: struct {
}

clean_up_resources :: (using utility : *$UtilityType/interface EditorUtilityCommon) {
    if UtilityType == SpriteCutter {
        if image_for_cut.texture.render_id != 0 {
            sprite_delete(*image_for_cut);
        }
        if sprite_preview.texture.render_id != 0 {
            sprite_delete(*sprite_preview);
        }
    }
}

clean_up_resources :: (utility : *EditorUtility) {
    if #complete utility.tag == {
    case .NONE;
    case .SPRITE_CUTTER;
        clean_up_resources(*utility.sprite_cutter);
    case .WORLD_VIEW;
    }
}

utility_set_transient_data :: (utility: *EditorUtility, transient_data: *EditorUtility_Transient) {
    if #complete utility.tag == {
    case .NONE;
    case .SPRITE_CUTTER;
        transient_data.sprite_cutter_transient = .{};
        utility.sprite_cutter.transient_data = *transient_data.sprite_cutter_transient;
    case .WORLD_VIEW;
    }
}

utility_present_menu :: (utility: *EditorUtility) {
    if #complete utility.tag == {
    case .NONE;
    case .SPRITE_CUTTER;
        sprite_cutter_menu(*utility.sprite_cutter);
    case .WORLD_VIEW;
    }
}

utility_update_and_present_graphics :: (utility: *EditorUtility) {
    if #complete utility.tag == {
    case .NONE;
    case .SPRITE_CUTTER;
        sprite_cutter_update(*utility.sprite_cutter);
        sprite_cutter_present_graphics(*utility.sprite_cutter);
    case .WORLD_VIEW;
    }
}
