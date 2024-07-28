
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --------------------------------------------------------------------------------------------------------- ring buffer
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
RingBufferBase :: struct {}
RingBuffer :: struct($ItemType: Type, $IN_COUNT: s64) {
    #run assert(IN_COUNT > 0);
    using #as base: RingBufferBase;
    items: [IN_COUNT]ItemType;
    front: s32;
    back: s32;
    count: s32;
}

ring_buffer_push :: (buffer: *$T/interface RingBufferBase, item: buffer.ItemType) {
    using buffer;
    items[back] = item;
    old_back := back;
    ring_buffer_increment_index(buffer, *back);
    if front == old_back 
        then front = back;
        else count += 1;
}

ring_buffer_pop :: (buffer: *$T/interface RingBufferBase) -> buffer.ItemType {
    using buffer;
    assert(count > 0);
    item := items[front];
    ring_buffer_decrement_index(buffer, *front);
    count -= 1;
    return item;
}

ring_buffer_increment_index :: (buffer: *$T/interface RingBufferBase, index: *s32) {
    using buffer;
    <<index += 1;
    if <<index >= items.count then <<index = 0;
}

ring_buffer_decrement_index :: (buffer: *$T/interface RingBufferBase, index: *s32) {
    <<index -= 1;
    if <<index < 0 then <<index = items.count - 1;
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --------------------------------------------------------------------------------------------------------- static pool
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

PoolItem :: struct {
    _pooled_item_in_use := false;
}

StaticPool :: struct($ItemType: Type, $count : u32) {
    items : [count]ItemType;
    mutex: Mutex;
}

static_pool_init :: (pool: *StaticPool($T, $COUNT)) {
    init(*pool.mutex, "Static Pool");
}

static_pool_request :: (pool: *StaticPool($T, $COUNT)) -> *T {
    lock(*pool.mutex);
    defer unlock(*pool.mutex);
    for *item : pool.items {
        if !item._pooled_item_in_use {
            item._pooled_item_in_use = true;
            return item;
        }
    }
    return null;
}

static_pool_get_item_index :: (pool: *StaticPool($T, $COUNT), item: *T, $do_lock := true) -> s64 #expand {
    #if do_lock {
        lock(*pool.mutex);
        defer unlock(*pool.mutex);
    }
    assert(item._pooled_item_in_use);
    i := (cast(s64) item - cast(s64) *pool.items[0]) / size_of(T);
    assert(i >= 0 && i < pool.items.count);
    return i;
}

static_pool_return :: (pool: *StaticPool($T, $COUNT), item: *T) {
    lock(*pool.mutex);
    defer unlock(*pool.mutex);
    // using for validation
    static_pool_get_item_index(pool, item, false);
    <<item = T.{};
    item._pooled_item_in_use = false;
}

static_pool_count_used :: (pool: *StaticPool($T, $COUNT)) -> u32 {
    lock(*pool.mutex);
    defer unlock(*pool.mutex);
    count : u32;
    for pool.items {
        if it._pooled_item_in_use then count += 1;
    }
    return count;
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// -------------------------------------------------------------------------------------------------------- dynamic pool
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

DynamicPool :: struct($ItemType: Type) {
    items: [..]ItemType;
    in_use: [..]u8;
    mutex: Mutex;
}

dynamic_pool_init :: (pool: *DynamicPool($T)) {
    init(*pool.mutex, "Dynamic Pool");
}

dynamic_pool_deinit :: (using pool: *DynamicPool($T)) {
    array_free(items);
    items.data = null;
    items.count = 0;
    array_free(in_use);
    in_use.data = null;
    in_use.count = 0;
}

dynamic_pool_request :: (using pool: *DynamicPool($T)) -> s64 {
    lock(*mutex);
    defer unlock(*mutex);
    for i : 0..in_use.count-1 {
        in_use_chunk := in_use[i];
        if (in_use_chunk & U8_MAX) != U8_MAX {
            for shift : 0..7 {
                shifted_bit := 1 << shift;
                if (in_use_chunk & shifted_bit) == 0 {
                    in_use[i] |= shifted_bit;
                    item_index := i * 8 + shift;
                    return *items[item_index];
                }
            }
        }
    }
    prev_item_count := items.count;
    array_resize(*items, items.count + 8);
    array_add(*in_use, 0);
    in_use[in_use.count-1] |= 1;
    return *items[prev_item_count];
}

dynamic_pool_get_item :: (using pool: *StaticPool($T, $COUNT), item: s64) -> *T {
    assert(item >= 0 && item < items.count);
    return *items[item];
}

dynamic_pool_get_item_index :: (using pool: *StaticPool($T, $COUNT), item: *T, $do_lock := true) -> s64 #expand {
    #if do_lock {
        lock(*mutex);
        defer unlock(*mutex);
    }
    i := (cast(s64) item - cast(s64) *items[0]) / size_of(T);
    assert(i >= 0 && i < items.count);
    return i;
}

dynamic_pool_return :: (using pool: *DynamicPool($T), item: s64) {
    lock(*mutex);
    defer unlock(*mutex);
    assert(i >= 0 && i < items.count);
    items[item] = T.{};

    byte_index := item >> 3;
    bit_index := item - (byte_index << 3);
    in_use[byte_index] &= ~(1 << bit_index);
}
