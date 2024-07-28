
Collider2d :: struct {
    type : enum {
        BOX;
        CIRCLE;
    }
    union {
        box: RectBU = ---;
        circle: Circle = ---;
    }
}

EntityCollider :: struct {
    using position : Vector2;
    velocity : Vector2;
    up_direction : Vector2;
    collider : Collider2d;
    mass : float32;
}

EntityCollision :: struct {
    id_a: u32;
    id_b: u32;
}

make_entity_collider :: inline (e: *Entity) -> EntityCollider {
    return .{
        make_vector2(e.position),
        e.velocity,
        rotate(Vector3.{0.0, 1.0, 0.0}, e.orientation),
        e.collider,
        e.mass
    };
}

solve_collision :: (a : *EntityCollider, b: *EntityCollider) {

}
