#load "editor_utility.jai";
#load "sprite_cutter.jai";
#load "ui.jai";

editor_init_render :: () {
    using context.curry;
    render_data.top_down_mouse_pos = window_pos_y_flip(mouse.window_position);
}

editor_render :: () {
    draw_main_menu();
    draw_tab_bar();
    draw_side_bar();
    imgui_set_cursor();
}
    
editor_cleanup :: () {
    clean_up_ui_resources();
}

