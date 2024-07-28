
ScreenspaceLayer :: enum u8 {
     _0;  _1;  _2;  _3;  _4;  _5;  _6;  _7;
     _8;  _9; _10; _11; _12; _13; _14; _15;
    _16; _17; _18; _19; _20; _21; _22; _23; 
    _24; _25; _26; _27; _28; _29; _30; _31;
    _32; _33; _34; _35; _36; _37; _38; _39;
    _40; _41; _42; _43; _44; _45; _46; _47;
    _48; _49; _50; _51; _52; _53; _54; _55; 
    _56; _57; _58; _59; _60; _61; _62; _63;
}

SCREENSPACE_LAYER_COUNT :: #run (cast(*Type_Info_Enum) type_info(ScreenspaceLayer)).values.count;
SCREENSPACE_DEPTH :: 100.0;
SCREENSPACE_PADDED_DEPTH_PER_LAYER :: SCREENSPACE_DEPTH / SCREENSPACE_LAYER_COUNT;
SCREENSPACE_PADDING :: SCREENSPACE_PADDED_DEPTH_PER_LAYER * 0.01;
SCREENSPACE_DEPTH_PER_LAYER :: SCREENSPACE_PADDED_DEPTH_PER_LAYER - SCREENSPACE_PADDING * 2.005;

CAMERA_SCREENSPACE_NEAR_PLANE :: SCREENSPACE_PADDING * 0.99;
CAMERA_SCREENSPACE_FAR_PLANE :: SCREENSPACE_DEPTH;
CAMERA_NEAR_PLANE :: SCREENSPACE_DEPTH + SCREENSPACE_PADDING * 1.01;
CAMERA_FAR_PLANE :: 1_000_000.0;
CAMERA_WORLDSPACE_DEPTH :: (CAMERA_FAR_PLANE - CAMERA_NEAR_PLANE) / CAMERA_FAR_PLANE;
CAMERA_COMPUTED_SCREENSPACE_DEPTH :: 1.0 - CAMERA_WORLDSPACE_DEPTH;

CameraViewMode :: enum {
    ORTHOGRAPHIC;
    PERSPECTIVE;
};

CameraDimensionality :: enum {
    _2D;
    _3D;
}

ViewSettingsOrthographic :: struct {
    scale := 1.0;
    use_screenspace := false;
}

ViewSettingsPerspective :: struct {
    vertical_fov_degrees := 100.0;
    force_aspect_ratio := 0.0;
}

Camera :: struct {
    using entity := Entity.{};
    view_mode := CameraViewMode.ORTHOGRAPHIC;
    dimensionality := CameraDimensionality._2D;
    union {
        orthographic_settings : ViewSettingsOrthographic;
        perspective_settings : ViewSettingsPerspective;
    };
}

type_is_view_settings :: (T: Type) -> bool {
    if T == {
    case ViewSettingsOrthographic; #through;
    case ViewSettingsPerspective;
        return true;
    case;
        return false;
    }
}

camera_create :: (view_mode: CameraViewMode, dimensionality: CameraDimensionality, settings : $SettingsType) -> Camera
    #modify { return type_is_view_settings(SettingsType); }
{
    #if SettingsType == ViewSettingsOrthographic {
        assert(view_mode == .ORTHOGRAPHIC);
        position := Vector3.{0.0, 0.0, CAMERA_SCREENSPACE_NEAR_PLANE * 0.99};
        return Camera.{
            entity=.{position=position},
            view_mode=.ORTHOGRAPHIC, 
            dimensionality=dimensionality, 
            orthographic_settings=settings
        };
    } else {
        assert(view_mode == .PERSPECTIVE);
        return Camera.{view_mode=.PERSPECTIVE, dimensionality=dimensionality, perspective_settings=settings};
    }
}

camera_create :: (view_mode: CameraViewMode, dimensionality: CameraDimensionality) -> Camera {
    if view_mode == .ORTHOGRAPHIC {
        position := Vector3.{0.0, 0.0, CAMERA_SCREENSPACE_NEAR_PLANE * 0.99};
        return Camera.{
            entity=.{position=position},
            view_mode=.ORTHOGRAPHIC, 
            dimensionality=dimensionality
        };
    } else {
        assert(view_mode == .PERSPECTIVE);
        return Camera.{view_mode=.PERSPECTIVE, dimensionality=dimensionality};
    }
}

camera_set_orthographic :: (camera: *Camera, settings := ViewSettingsOrthographic.{}) {
    camera.view_mode = .ORTHOGRAPHIC;
    camera.orthographic_settings = settings;
}

camera_set_perspective :: (camera: *Camera, settings := ViewSettingsPerspective.{}) {
    camera.view_mode = .PERSPECTIVE;
    camera.perspective_settings = settings;
}

camera_right :: (camera: *Camera) -> Vector3 {
    if camera.dimensionality == ._2D
        then return .{1.0, 0.0, 0.0};
        else return rotate(.{1.0, 0.0, 0.0}, camera.orientation);        
}

camera_up :: (camera: *Camera) -> Vector3 {
    if camera.dimensionality == ._2D 
        then return .{0.0, 1.0, 0.0};
        else return rotate(.{0.0, 1.0, 0.0}, camera.orientation);        
}

camera_forward :: (camera: *Camera) -> Vector3 {
    if camera.dimensionality == ._2D
        then return .{0.0, 0.0, -1.0};
        else return rotate(.{0.0, 0.0, -1.0}, camera.orientation);        
}

camera_view_matrix :: (camera: *Camera) -> Matrix4 {
    look_at := camera.position + camera_forward(camera);
    return camera_look_at_matrix(camera, look_at);
}

camera_look_at_matrix :: (camera: *Camera, look_at: Vector3) -> Matrix4 {
    return make_look_at_matrix(camera.position, look_at, camera_up(camera), false);
}

camera_projection_matrix :: (camera: *Camera, viewport: Vector2) -> Matrix4 {
    if #complete camera.view_mode == {
    case .ORTHOGRAPHIC;
        scaled_view := viewport * (1.0 / camera.orthographic_settings.scale);
        if camera.orthographic_settings.use_screenspace {
            hz := scaled_view.x;
            vt := scaled_view.y;
            return orthographic_projection_matrix(0.0, hz, 0.0, vt, CAMERA_SCREENSPACE_NEAR_PLANE, CAMERA_FAR_PLANE);
        } else {
            hz := scaled_view.x * 0.5;
            vt := scaled_view.y * 0.5;
            m := orthographic_projection_matrix(-hz, hz, -vt, vt, CAMERA_SCREENSPACE_NEAR_PLANE, CAMERA_FAR_PLANE);
            // pushing the normalized world space into range [-1, begin screenspace) so that screenspace
            // and worldspace do not overlap in the depth buffer
            m._33 = m._33 * CAMERA_WORLDSPACE_DEPTH - CAMERA_COMPUTED_SCREENSPACE_DEPTH;
            m._34 = m._34 * CAMERA_WORLDSPACE_DEPTH - CAMERA_COMPUTED_SCREENSPACE_DEPTH;
            return m;
        }
    case .PERSPECTIVE;
        aspect_ratio := ifx camera.perspective_settings.force_aspect_ratio != 0.0
            then camera.perspective_settings.force_aspect_ratio
            else viewport.x / viewport.y;
        fov_radians := camera.perspective_settings.vertical_fov_degrees * (PI / 180.0);
        // TODO: no screenspace overlap for perspective
        return make_projection_matrix(fov_radians, aspect_ratio, CAMERA_SCREENSPACE_NEAR_PLANE, CAMERA_FAR_PLANE);
    }
    return Matrix4.{};
}

screenspace_layer_range :: (layer: ScreenspaceLayer) -> Vector2 {
    layer_float : float32 = xx ((SCREENSPACE_LAYER_COUNT-1) - cast(u8) layer);
    padded_base := SCREENSPACE_PADDED_DEPTH_PER_LAYER * layer_float + SCREENSPACE_PADDING;
    return .{-padded_base, -(padded_base + SCREENSPACE_DEPTH_PER_LAYER)};
}

screenspace_layer_middle :: (layer: ScreenspaceLayer) -> float32 {
    range := screenspace_layer_range(layer);
    return (range.x + range.y) * 0.5;
}
