
IntVector2 :: struct {
    x, y: s32;

    #place x;
        component: [2]s32 = ---;
}

// a y-up or 'bottom up' rect
RectBU :: struct {
    lower_left: IntVector2;
    upper_right: IntVector2;
}

// a y-down or 'top down' rect
RectTD :: struct {
    upper_left: IntVector2;
    lower_right: IntVector2;
}

FloatRectTD :: struct {
    upper_left: Vector2;
    lower_right: Vector2;
}

make_rect_bu :: inline (viewport_rect: ViewportRect) -> RectBU {
    return RectBU.{
        viewport_rect.bottom_left,
        viewport_rect.bottom_left + viewport_rect.dimensions
    };
}

make_rect_bu :: inline (rect_td: RectTD) -> RectBU {
    return RectBU.{
        .{rect_td.upper_left.x, rect_td.lower_right.y},
        .{rect_td.lower_right.x, rect_td.upper_left.y}
    };
}

make_rect_td :: inline (viewport_rect: ViewportRect) -> RectTD {
    rect_bu := make_rect_bu(viewport_rect);
    rect_td := RectTD.{window_pos_y_flip(rect_bu.lower_left), window_pos_y_flip(rect_bu.upper_right)};
    return .{.{rect_td.upper_left.x, rect_td.lower_right.y}, .{rect_td.lower_right.x, rect_td.upper_left.y}};
}

point_inside_rect :: inline (rect: RectTD, point: IntVector2) -> bool {
    return point.x >= rect.upper_left.x 
        && point.x <= rect.lower_right.x
        && point.y >= rect.upper_left.y
        && point.y <= rect.lower_right.y;
}

point_inside_rect :: inline (rect: FloatRectTD, point: Vector2) -> bool {
    return point.x >= rect.upper_left.x 
        && point.x <= rect.lower_right.x
        && point.y >= rect.upper_left.y
        && point.y <= rect.lower_right.y;
}

make_vector2 :: inline (v: IntVector2) -> Vector2 {
    return .{xx v.x, xx v.y};
}

make_vector3 :: inline (v: Vector2) -> Vector3 {
    return .{v.x, v.y, 0.0};
}

make_intvector2 :: inline (v: Vector2) -> IntVector2 {
    return .{xx v.x, xx v.y};
}

operator + :: inline (a: IntVector2, b: IntVector2) -> IntVector2 {
    return .{a.x + b.x, a.y + b.y};
}

operator - :: inline (a: IntVector2, b: IntVector2) -> IntVector2 {
    return .{a.x - b.x, a.y - b.y};
}

operator * :: inline (a: IntVector2, b: IntVector2) -> IntVector2 {
    return .{a.x * b.x, a.y * b.y};
}

operator / :: inline (a: IntVector2, b: IntVector2) -> IntVector2 {
    return .{a.x / b.x, a.y / b.y};
}

operator + :: inline (a: IntVector2, b: s32) -> IntVector2 {
    return .{a.x + b, a.y + b};
}

operator - :: inline (a: IntVector2, b: s32) -> IntVector2 {
    return .{a.x - b, a.y - b};
}

operator * :: inline (a: IntVector2, b: s32) -> IntVector2 {
    return .{a.x * b, a.y * b};
}

operator + :: inline (a: Vector3, b: Vector2) -> Vector3 {
    return .{a.x + b.x, a.y + b.y, a.z};
}

viewport_view_projection_matrix :: inline (camera: Camera, viewport_rect: ViewportRect) -> Matrix4 {
    scalar_viewport := Vector2.{xx viewport_rect.dimensions.x, xx viewport_rect.dimensions.y};
    view := camera_view_matrix(*camera);
    projection := camera_projection_matrix(*camera, scalar_viewport);
    return projection * view;
}

