
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
