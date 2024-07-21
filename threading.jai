
ThreadSyncInfo :: struct {
    work_start : u8;
    work_done : u8 = 1;    
    should_quit : bool;
}

CurryThread :: struct {
    using #as thread: Thread;
    using sync_info: ThreadSyncInfo;
    curry_instance: *Curry;
}

Fence :: struct {
    fence: *u8;
    do_reset := true;
}

wait_for_fence :: (fence: Fence) {
    while atomic_read(fence.fence) == 0 {
        do_sleep(0.1);
    }
    if fence.do_reset then atomic_write(fence.fence, 0);
}

// the only usage of this that potentially resets multiple fences and is thread safe would use mutexes
// to read and write in one go. so.. add mutexes to system so this is more valuable? think about it
wait_for_any_fence :: (fences: ..Fence) {
    while true {
        for fences {
            if atomic_read(it.fence) != 0 {
                if it.do_reset {
                    atomic_write(it.fence, 0);
                }
                return;
            }
        }
        do_sleep(0.1);
    }
}

wait_for_all_fences :: (fences: ..Fence) {
    while true {
        passed_count := 0;
        for fences {
            passed_count += atomic_read(it.fence) != 0;
        }
        if passed_count == fences.count {
            for fences {
                if it.do_reset {
                    atomic_write(it.fence, 0);
                }
            }
            return;
        }
        do_sleep(0.1);
    }
}

signal_fence :: inline (fence: *u8) {
    atomic_write(fence, 1);
}

create_thread :: () -> *CurryThread {
    thread := New(CurryThread);
    thread.curry_instance = context.curry;
    return thread;
}

delete_thread :: (thread: *CurryThread) {
    thread.should_quit = true;
    thread.work_start = xx true;
    while !thread_is_done(xx thread) {
        do_sleep(0.1);
    }
    thread_deinit(*thread.thread);
    free(*thread.thread);
}
