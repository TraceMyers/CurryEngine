
IntVector2 :: struct {
    x, y: s32;

    #place x;
        component: [2]s32 = ---;
}

Rect :: struct {
    lower_left: IntVector2;
    upper_right: IntVector2;
}

make_vector2 :: (v: IntVector2) -> Vector2 {
    return .{xx v.x, xx v.y};
}

make_vector2 :: (v: Vector2) -> Vector2 {
    return v;
}

operator + :: (a: IntVector2, b: IntVector2) -> IntVector2 {
    return .{a.x + b.x, a.y + b.y};
}

operator - :: (a: IntVector2, b: IntVector2) -> IntVector2 {
    return .{a.x - b.x, a.y - b.y};
}

operator * :: (a: IntVector2, b: IntVector2) -> IntVector2 {
    return .{a.x * b.x, a.y * b.y};
}

operator / :: (a: IntVector2, b: IntVector2) -> IntVector2 {
    return .{a.x / b.x, a.y / b.y};
}

operator + :: (a: IntVector2, b: s32) -> IntVector2 {
    return .{a.x + b, a.y + b};
}

operator - :: (a: IntVector2, b: s32) -> IntVector2 {
    return .{a.x - b, a.y - b};
}

operator * :: (a: IntVector2, b: s32) -> IntVector2 {
    return .{a.x * b, a.y * b};
}

viewport_view_projection_matrix :: inline (camera: Camera, viewport_rect: ViewportRect) -> Matrix4 {
    scalar_viewport := Vector2.{xx viewport_rect.dimensions.x, xx viewport_rect.dimensions.y};
    view := camera_view_matrix(*camera);
    projection := camera_projection_matrix(*camera, scalar_viewport);
    return projection * view;
}
