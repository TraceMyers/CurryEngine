// TODO: consider, depending on the utility, cleaning up and re-instantiating when a tab is not active

ToolTab :: struct {
    utility: EditorUtility;
    id : u32 = 0;
}

CloseTabMenu :: struct {
    tab_index: u32;
    top_down_location: Vector2;
    active := false;
}

GuiRenderData :: struct {
    using #as editor_settings: EditorSettings;
    top_down_mouse_pos: IntVector2;
    main_menu_height: float32;
    tab_bar_height: float32;
    left_click_hold_start := IntVector2;
    resizing_side_bar := false;
    side_bar_collapsed := false;
}

SIDE_BAR_WIDTH_DEFAULT :: 200.0;
SCROLL_ZOOM_SPEED_DEFAULT :: 12.0;

EditorSettings :: struct {
    side_bar_width := SIDE_BAR_WIDTH_DEFAULT;
    scroll_zoom_speed := SCROLL_ZOOM_SPEED_DEFAULT;
}

render_data: GuiRenderData;
tool_tabs: [..]ToolTab;
active_tool_tab := -1;
close_tab_menu: CloseTabMenu;
tab_id_counter : u32 = 0;
TAB_BAR_BUFFER :: 5.0;

draw_main_menu :: () {
    DARK_GREEN_BLUE :: Color4f.{0.04, 0.22, 0.38, 0.95};

    style := ImGui.GetStyle();

    menu_background_color := style.Colors[ImGui.Col.MenuBarBg];
    style.Colors[ImGui.Col.MenuBarBg] = xx DARK_GREEN_BLUE;
    defer style.Colors[ImGui.Col.MenuBarBg] = menu_background_color;

    init_tab_count := tool_tabs.count;
    render_data.main_menu_height = 0.0;

    if ImGui.BeginMainMenuBar() {
        if ImGui.BeginMenu("Tools") {
            if ImGui.MenuItem("Sprite Cutter") {
                array_add(*tool_tabs, .{
                    .{
                        tag=.SPRITE_CUTTER,
                        sprite_cutter=.{
                            common=.{
                                layout=.DUET_TOP_BOTTOM, 
                                layout_proportion=0.5, 
                                view_scale=1.0
                            }
                        }
                    }, 
                    tab_id_counter
                });
            } 
            ImGui.EndMenu();
        }

        if tool_tabs.count > init_tab_count {
            tab_id_counter += 1;
            active_tool_tab = tool_tabs.count - 1;
        }

        if ImGui.BeginMenu("Settings") {
            ImGui.ColorEdit3("Clear Color", xx *context.curry.window_settings.clear_color);
            ImGui.SetNextItemWidth(90.0);
            ImGui.InputFloat("Global Scroll Zoom Speed", *render_data.scroll_zoom_speed, 1.0, 10.0, "%.f");
            ImGui.SameLine();
            if ImGui.Button("reset") then render_data.scroll_zoom_speed = SCROLL_ZOOM_SPEED_DEFAULT;
            ImGui.EndMenu();
        }

        render_data.main_menu_height = ImGui.GetWindowSize().y;
        ImGui.EndMainMenuBar();
    }
}

draw_tab_bar :: () {
    TAB_BAR_HEIGHT :: 16.0;
    TAB_WINDOW_FLAGS : ImGui.WindowFlags : .NoTitleBar | .NoResize | .NoMove;
    DARK_GREEN_BLUE :: Color4f.{0.04, 0.22, 0.38, 1.0};
    GREEN_BLUE :: Color4f.{0.15, 0.38, 0.55, 1.0};
    FRIENDLY_GREEN :: Color4f.{0.2, 0.4, 0.52, 1.0};
    GREY_BLUE :: Color4f.{0.2, 0.33, 0.43, 1.0};
    MID_BLUE :: Color4f.{0.1, 0.3, 0.42, 0.95};

    style := ImGui.GetStyle();

    button_color := style.Colors[ImGui.Col.Button];
    defer style.Colors[ImGui.Col.Button] = button_color;

    button_hover_color := style.Colors[ImGui.Col.ButtonHovered];
    defer style.Colors[ImGui.Col.ButtonHovered] = button_hover_color;

    button_active_color := style.Colors[ImGui.Col.ButtonActive];
    style.Colors[ImGui.Col.ButtonActive] = xx FRIENDLY_GREEN;
    defer style.Colors[ImGui.Col.ButtonActive] = button_active_color;

    window_background_color := style.Colors[ImGui.Col.WindowBg];
    style.Colors[ImGui.Col.WindowBg] = xx MID_BLUE;
    defer style.Colors[ImGui.Col.WindowBg] = window_background_color;

    ImGui.PushStyleVar(.WindowPadding, .{}); 
    defer ImGui.PopStyleVar();
    ImGui.PushStyleVar(.WindowBorderSize, 0.0); 
    defer ImGui.PopStyleVar();
    ImGui.PushStyleVar(.WindowMinSize, .{}); 
    defer ImGui.PopStyleVar();
    ImGui.PushStyleVar(.ItemSpacing, .{3.0, 0.0});
    defer ImGui.PopStyleVar();

    if close_tab_menu.active {
        ImGui.PushStyleVar(.ItemSpacing, .{0.0, 0.0});
        defer ImGui.PopStyleVar();
        ImGui.SetNextWindowPos(xx close_tab_menu.top_down_location);
        ImGui.SetNextWindowSize(.{40.0, TAB_BAR_HEIGHT});

        if ImGui.Begin("##CloseTabMenu", null, TAB_WINDOW_FLAGS) {
            if ImGui.MenuItem("close") {
                using close_tab_menu;
                clean_up_resources(*tool_tabs[tab_index].utility);
                array_unordered_remove_by_index(*tool_tabs, tab_index);
                if tab_index <= active_tool_tab then active_tool_tab -= 1;
                if active_tool_tab < 0 && tool_tabs.count > 0 then active_tool_tab = 0;
                active = false;
            } else {
                close_menu_rect: PointRectTD = ---;
                BUFFER_PIXELS :: 5;
                using close_menu_rect;
                upper_left = make_intvector2(ImGui.GetWindowPos()) - BUFFER_PIXELS;
                lower_right = upper_left + make_intvector2(ImGui.GetWindowSize()) + BUFFER_PIXELS;
                if !point_inside_rect(close_menu_rect, render_data.top_down_mouse_pos) 
                    then close_tab_menu.active = false;
            }
            ImGui.End();
        }
    }

    ImGui.SetNextWindowPos(.{0.0, render_data.main_menu_height + TAB_BAR_BUFFER});
    ImGui.SetNextWindowSize(.{xx context.curry.window_settings.width, TAB_BAR_HEIGHT});

    // draw a black box in the gap between the tab bar and main menu so the clear color doesn't show through
    draw_screenspace_box(
        window_pos_y_flip(.{0.0, render_data.main_menu_height}), 
        window_pos_y_flip(.{xx context.curry.window_settings.width, render_data.main_menu_height + TAB_BAR_BUFFER}),
        COLOR4B_BLACK,
        0.0,
        ._0,
        true
    );

    render_data.tab_bar_height = 0.0;
    if ImGui.Begin("##TabBar", null, TAB_WINDOW_FLAGS) {
        defer ImGui.End();
        for tool_tabs {
            is_active := false;
            if it_index == active_tool_tab {
                is_active = true;
                style.Colors[ImGui.Col.Button] = xx GREEN_BLUE;
                style.Colors[ImGui.Col.ButtonHovered] = xx GREEN_BLUE;
            } else {
                style.Colors[ImGui.Col.Button] = xx DARK_GREEN_BLUE;
                style.Colors[ImGui.Col.ButtonHovered] = xx GREY_BLUE;
            }
            ImGui.SameLine();

            tab_rect: PointRectTD = ---;
            tab_rect.upper_left = make_intvector2(ImGui.GetCursorPos());
            if ImGui.Button(temp_c_string(tprint("%##%", tab_name(it_index, 32), it.id))) {
                active_tool_tab = it_index;
            }
            ImGui.SameLine();
            tab_rect.lower_right = make_intvector2(ImGui.GetCursorPos());

            tab_rect.upper_left.y = xx (render_data.main_menu_height + xx TAB_BAR_BUFFER);
            tab_rect.lower_right.y = xx (render_data.main_menu_height + (xx TAB_BAR_BUFFER) + TAB_BAR_HEIGHT);

            if point_inside_rect(tab_rect, render_data.top_down_mouse_pos) && mouse.right.just_pressed.fixed_state {
                using close_tab_menu;
                tab_index = xx it_index;
                top_down_location = make_vector2(render_data.top_down_mouse_pos); 
                active = true;
            }
        }
        render_data.tab_bar_height = ImGui.GetWindowSize().y;
    }
}

draw_side_bar :: () {
    using context.curry;

    if tool_tabs.count <= 0 then return;

    SIDE_BAR_FLAGS: ImGui.WindowFlags: .NoResize | .NoMove;
    DARK_BLUISH_GREY :: Color4f.{0.102, 0.105, 0.12, 1.0};
    MIN_SIDE_BAR_WIDTH :: 32.0;
    min_side_bar_width := min(MIN_SIDE_BAR_WIDTH, cast(float32) window_settings.width);
    max_side_bar_width := max(cast(float32) window_settings.width - MIN_SIDE_BAR_WIDTH, MIN_SIDE_BAR_WIDTH);

    style := ImGui.GetStyle();
    io := ImGui.GetIO();
    
    bg_color := style.Colors[ImGui.Col.WindowBg];
    style.Colors[ImGui.Col.WindowBg] = xx DARK_BLUISH_GREY;
    defer style.Colors[ImGui.Col.WindowBg] = bg_color;

    title_bg_color := style.Colors[ImGui.Col.TitleBg];
    style.Colors[ImGui.Col.TitleBg] = xx Color4f.{0.08, 0.08, 0.08, 1.0};
    defer style.Colors[ImGui.Col.TitleBg] = title_bg_color;

    title_bg_color_active := style.Colors[ImGui.Col.TitleBgActive];
    style.Colors[ImGui.Col.TitleBgActive] = xx Color4f.{0.08, 0.08, 0.08, 1.0};
    defer style.Colors[ImGui.Col.TitleBg] = title_bg_color_active;

    title_bg_color_collapsed := style.Colors[ImGui.Col.TitleBgCollapsed];
    style.Colors[ImGui.Col.TitleBgCollapsed] = xx Color4f.{0.0, 0.0, 0.0, 0.0};
    defer style.Colors[ImGui.Col.TitleBg] = title_bg_color_collapsed;

    TITLE_BAR_HEIGHT :: 24.0;
    side_bar_ypos := render_data.main_menu_height + render_data.tab_bar_height + TAB_BAR_BUFFER;
    side_bar_height : float32 = ifx render_data.side_bar_collapsed 
        then TITLE_BAR_HEIGHT
        else cast(float32) window_settings.height - side_bar_ypos;

    // resize the bar widthwise
    // TODO: figure out something better than io.WantCaptureMouse, because imgui wants to capture the mouse
    // just because a window is just being hovered (no elements inside window hovered).
    if !io.WantCaptureMouse {
        RIGHT_EDGE_HOVER_BUFFER :: 8.0;
        right_edge_rect: PointRectTD = ---;
        lr_y := side_bar_ypos + side_bar_height;
        using right_edge_rect;
        upper_left = .{
            xx max(render_data.side_bar_width - RIGHT_EDGE_HOVER_BUFFER, 0.0), xx side_bar_ypos
        };
        lower_right = .{
            xx max(render_data.side_bar_width + RIGHT_EDGE_HOVER_BUFFER, 0.0), xx (side_bar_ypos + side_bar_height)
        };
        if point_inside_rect(right_edge_rect, render_data.top_down_mouse_pos) {
            ImGui.SetMouseCursor(.ResizeEW);
            if mouse.left.just_pressed.fixed_state then render_data.resizing_side_bar = true;
        }
    }

    if mouse.left.down.fixed_state && render_data.resizing_side_bar
        then render_data.side_bar_width = clamp(cast(float32) mouse.x, min_side_bar_width, max_side_bar_width);
        else render_data.resizing_side_bar = false;

    render_data.side_bar_width = clamp(render_data.side_bar_width, min_side_bar_width, max_side_bar_width);

    ImGui.SetNextWindowPos(.{0.0, side_bar_ypos}); 
    ImGui.SetNextWindowSize(.{render_data.side_bar_width, side_bar_height});

    sidebar_identifier := temp_c_string(active_side_bar_name());
    active_tab := *tool_tabs[active_tool_tab];

    // viewport not including side bar (in case side bar is not rendered)
    push_viewport(.{
        offset_top.type=.PIXEL_COUNT,
        offset_top.pixel_count = xx side_bar_ypos
    }, true);

    transient_data: EditorUtility_Transient;
    utility_set_transient_data(*active_tab.utility, *transient_data);

    if ImGui.Begin(sidebar_identifier, null, SIDE_BAR_FLAGS) {
        render_data.side_bar_collapsed = false;
        utility_present_menu(*active_tab.utility);
        //viewport including side bar
        push_viewport(.{
            offset_left.type=.PIXEL_COUNT,
            offset_left.pixel_count = xx render_data.side_bar_width,
        }, true);

    } else render_data.side_bar_collapsed = true;
    ImGui.End();

    utility_update_and_present_graphics(*active_tab.utility);

    if !render_data.side_bar_collapsed then pop_viewport();
}

tab_name :: (index: s64, cutoff_char_ct := 120) -> string {
    tab := *tool_tabs[index];
    tab_name: string;

    // always leave room for ellipsis
    ELLIPSIS_DOT_COUNT :: 2;
    cutoff_char_ct = max(cutoff_char_ct, ELLIPSIS_DOT_COUNT);

    if #complete tab.utility.tag == {
    case .NONE;
        tab_name = "None";
    case .SPRITE_CUTTER;
        SPRITE_CUTTER_BASE_COUNT :: 15;
        file_name := file_name_in_path(tab.utility.sprite_cutter.image_for_cut.texture.asset_path);
        tab_name = tprint("Sprite Cutter [%]", file_name);
    case .WORLD_VIEW;
        tab_name = "World View";
    }

    // cutoff w/ ellipsis
    if tab_name.count > cutoff_char_ct {
        for i: cutoff_char_ct-ELLIPSIS_DOT_COUNT..cutoff_char_ct-1 {
            tab_name[i] = #char ".";
        }
        tab_name.count = cutoff_char_ct;
    }
    
    return tab_name;
}

active_side_bar_name :: () -> string {
    active_tab := *tool_tabs[active_tool_tab];
    return tprint("%##SideBar_TabID=%", tab_name(active_tool_tab), active_tab.id);
}


clean_up_ui_resources :: () {
    for tab : tool_tabs {
        clean_up_resources(*tab.utility);
    }
    array_free(tool_tabs);
    tool_tabs.data = null;
    tool_tabs.count = 0;
}

imgui_indent :: (indent_amt : float32) #expand {
    ImGui.Indent(indent_amt);
    defer ImGui.Unindent(indent_amt);
}

do_standard_viewport_highlight :: inline () {
    highlight_last_cached_viewport(2.0, Color4b.{rgb=COLOR3B_YELLOW, a=100}, COLOR4B_TRANSPARENT);
}

