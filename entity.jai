
EntityDataPack :: struct {
    entities: StaticPool(Entity, MAX_ENTITY_COUNT);
    entity_colliders: [MAX_ENTITY_COUNT]EntityCollider;
    pending_entity_collisions: [..]EntityCollision;
}

Entity :: struct {
    using position : Vector3;
    orientation : Quaternion;
    scale := 1.0;
    velocity : Vector2;
    collider : Collider2d;
    mass := 1.0;

    entity_id : s32 = -1;
    sprite_id : s32 = -1;
    using pool_item : PoolItem;
}

make_entity :: () -> *Entity {
    using context.curry.entity_data;
    e := static_pool_request(*entities);
    if e then e.entity_id = static_pool_get_item_index(*entities, e);
    return e;
}
