## Tab bar that can show tabs in multiple lines (wrap), when there is not enough horizontal space.
@tool
extends PanelContainer

const CLOSE_BTN_SPACER: String = "    "

const CustomTab := preload("custom_tab.gd")

@onready var multiline_tab_bar: HFlowContainer = %MultilineTabBar
@onready var split_btn: Button = %SplitBtn
@onready var popup_btn: Button = %PopupBtn

#region Theme
var tab_hovered: StyleBoxFlat
var tab_focus: StyleBoxFlat
var tab_selected: StyleBoxFlat
var tab_unselected: StyleBoxFlat

var font_selected_color: Color
var font_unselected_color: Color
var font_hovered_color: Color
#endregion

var show_close_button_always: bool = false : set = set_show_close_button_always
var is_singleline_tabs: bool = false : set = set_singleline_tabs

var tab_group: ButtonGroup = ButtonGroup.new()

# Existing components, set from the plugin
var script_filter_txt: LineEdit
var scripts_item_list: ItemList
var scripts_tab_container: TabContainer
var popup: PopupPanel
# Reference back to the plugin, untyped
var plugin: EditorPlugin

var suppress_theme_changed: bool

var split_script: Script
var split_icon: Texture2D
var last_drag_over_tab: CustomTab
var drag_marker: ColorRect
var current_tab: CustomTab

## Tracks when each item_index was last selected, for temperature sorting.
var tab_select_times: Dictionary = {}
## True while ctrl+tab cycling is in progress; suppresses temperature updates.
var is_cycling_tabs: bool = false
## Frame number until which temperature updates are suppressed (for right-click, close).
var suppress_temperature_until_frame: int = -1

func _init() -> void:
	tab_group.pressed.connect(on_new_tab_selected)

#region Plugin and related tab handling processing
func _ready() -> void:
	popup_btn.pressed.connect(show_popup)
	split_btn.gui_input.connect(on_right_click)
	split_icon = split_btn.icon

	set_process(false)

	if (plugin != null):
		schedule_update()

func _notification(what: int) -> void:
	if (what == NOTIFICATION_DRAG_END || what == NOTIFICATION_MOUSE_EXIT):
		clear_drag_mark()
		return

	if (what == NOTIFICATION_THEME_CHANGED):
		if (suppress_theme_changed):
			return

		suppress_theme_changed = true
		add_theme_stylebox_override(&"panel", EditorInterface.get_editor_theme().get_stylebox(&"tabbar_background", &"TabContainer"))
		suppress_theme_changed = false

		tab_hovered = EditorInterface.get_editor_theme().get_stylebox(&"tab_hovered", &"TabContainer")
		tab_focus = EditorInterface.get_editor_theme().get_stylebox(&"tab_focus", &"TabContainer")
		tab_selected = EditorInterface.get_editor_theme().get_stylebox(&"tab_selected", &"TabContainer")
		tab_unselected = EditorInterface.get_editor_theme().get_stylebox(&"tab_unselected", &"TabContainer")

		if (drag_marker == null):
			drag_marker = ColorRect.new()
			drag_marker.set_anchors_and_offsets_preset(PRESET_LEFT_WIDE)
			drag_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
			drag_marker.custom_minimum_size.x = 4 *  EditorInterface.get_editor_scale()
		drag_marker.color = EditorInterface.get_editor_theme().get_color(&"drop_mark_color", &"TabContainer")

		font_hovered_color = EditorInterface.get_editor_theme().get_color(&"font_hovered_color", &"TabContainer")
		font_selected_color = EditorInterface.get_editor_theme().get_color(&"font_selected_color", &"TabContainer")
		font_unselected_color = EditorInterface.get_editor_theme().get_color(&"font_unselected_color", &"TabContainer")

		if (plugin == null || multiline_tab_bar == null):
			return

		for tab: CustomTab in get_tabs():
			update_tab_style(tab)

func _process(delta: float) -> void:
	sync_tabs_with_item_list()
	set_process(false)

func _shortcut_input(event: InputEvent) -> void:
	if (!event.is_pressed() || event.is_echo()):
		return

	if (!is_visible_in_tree()):
		return

	if (current_tab == null):
		return

	if (plugin.tab_cycle_forward_shc.matches_event(event)):
		get_viewport().set_input_as_handled()

		var tab_count: int = get_tab_count()
		if (tab_count <= 1):
			return

		is_cycling_tabs = true

		# Cycle through visual order (temperature-sorted).
		var tabs: Array[Node] = get_tabs()
		var index: int = tabs.find(current_tab)
		var new_index: int = (index + 1) % tab_count

		var tab: CustomTab = tabs[new_index]
		tab.button_pressed = true
	elif (plugin.tab_cycle_backward_shc.matches_event(event)):
		get_viewport().set_input_as_handled()

		var tab_count: int = get_tab_count()
		if (tab_count <= 1):
			return

		is_cycling_tabs = true

		# Cycle through visual order (temperature-sorted).
		var tabs: Array[Node] = get_tabs()
		var index: int = tabs.find(current_tab)
		var new_index: int = (index - 1 + tab_count) % tab_count

		var tab: CustomTab = tabs[new_index]
		tab.button_pressed = true

func _input(event: InputEvent) -> void:
	if (!is_cycling_tabs):
		return

	# Commit temperature when the modifier key (Ctrl) is released.
	if (event is InputEventKey && !event.is_pressed() && event.keycode == KEY_CTRL):
		is_cycling_tabs = false
		if (current_tab != null):
			tab_select_times[current_tab.item_index] = Time.get_ticks_msec()
			sort_tabs_by_temperature()

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if !(data is Dictionary):
		return false

	var can_drop: bool = data.has("index") && data["index"] != get_tab_count() - 1

	if (can_drop):
		on_drag_over(get_tab(get_tab_count() - 1))

	return can_drop

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if (!_can_drop_data(at_position, data)):
		return

	on_drag_drop(data["index"], get_tab_count() - 1)
#endregion

func schedule_update():
	set_process(true)

## Suppress temperature updates for the next 2 frames (covers deferred callbacks).
func suppress_temperature():
	suppress_temperature_until_frame = Engine.get_process_frames() + 2

func is_temperature_suppressed() -> bool:
	return Engine.get_process_frames() <= suppress_temperature_until_frame

func set_split(script: Script) -> void:
	split_script = script

	if (split_script != null):
		split_btn.icon = split_icon

		var text: String = scripts_item_list.get_item_text(current_tab.item_index)
		var icon: Texture2D = scripts_item_list.get_item_icon(current_tab.item_index)
		split_btn.text = text
		split_btn.icon = icon
	else:
		split_btn.icon = split_icon
		split_btn.text = ""

func is_split() -> bool:
	return split_script != null

func on_right_click(event: InputEvent):
	if (!split_btn.button_pressed):
		return

	if !(event is InputEventMouseButton):
		return

	var mouse_event: InputEventMouseButton = event

	if (!mouse_event.is_pressed() || mouse_event.button_index != MOUSE_BUTTON_RIGHT):
		return

	EditorInterface.edit_script(split_script)
	split_btn.button_pressed = false

func on_drag_drop(source_index: int, target_index: int):
	var child: Node = scripts_tab_container.get_child(source_index)
	scripts_tab_container.move_child(child, target_index);

	var tab: CustomTab = get_tab(target_index)
	tab.grab_focus()

func on_drag_over(tab: CustomTab):
	if (last_drag_over_tab == tab):
		return

	# The drag marker should always be orphan when here.
	tab.add_child(drag_marker)

	last_drag_over_tab = tab

func clear_drag_mark():
	if (last_drag_over_tab == null):
		return

	last_drag_over_tab = null
	if (drag_marker.get_parent() != null):
		drag_marker.get_parent().remove_child(drag_marker)

func update_tabs():
	update_script_text_filter()

	for tab: CustomTab in get_tabs():
		update_tab(tab)

func get_tabs() -> Array[Node]:
	return multiline_tab_bar.get_children()

func update_selected_tab():
	update_tab(tab_group.get_pressed_button())

func update_tab(tab: CustomTab):
	if (tab == null):
		return

	var index: int = tab.item_index

	tab.text = scripts_item_list.get_item_text(index)
	tab.icon = scripts_item_list.get_item_icon(index)
	tab.tooltip_text = scripts_item_list.get_item_tooltip(index)

	update_icon_color(tab, scripts_item_list.get_item_icon_modulate(index))

	if (scripts_item_list.is_selected(index)):
		tab.button_pressed = true
		tab.text += CLOSE_BTN_SPACER
	elif (show_close_button_always):
		tab.text += CLOSE_BTN_SPACER

func get_tab(index: int) -> CustomTab:
	if (index < 0 || index >= get_tab_count()):
		return null

	return multiline_tab_bar.get_child(index)

func get_tab_count() -> int:
	return multiline_tab_bar.get_child_count()

## Find a tab by its item_index (ItemList index), regardless of visual order.
func find_tab_by_item_index(item_index: int) -> CustomTab:
	for tab: CustomTab in get_tabs():
		if (tab.item_index == item_index):
			return tab
	return null

func add_tab(item_index: int) -> CustomTab:
	var tab: CustomTab = CustomTab.new()
	tab.button_group = tab_group
	tab.item_index = item_index

	if (show_close_button_always):
		tab.show_close_button()

	update_tab_style(tab)

	tab.close_pressed.connect(on_tab_close_pressed.bind(tab))
	tab.right_clicked.connect(on_tab_right_click.bind(tab))
	tab.mouse_exited.connect(clear_drag_mark)
	tab.dragged_over.connect(on_drag_over.bind(tab))
	tab.dropped.connect(on_drag_drop)

	multiline_tab_bar.add_child(tab)
	return tab

func update_tab_style(tab: CustomTab):
	tab.add_theme_stylebox_override(&"normal", tab_unselected)
	tab.add_theme_stylebox_override(&"hover", tab_hovered)
	tab.add_theme_stylebox_override(&"hover_pressed", tab_hovered)
	tab.add_theme_stylebox_override(&"focus", tab_focus)
	tab.add_theme_stylebox_override(&"pressed", tab_selected)

	tab.add_theme_color_override(&"font_color", font_unselected_color)
	tab.add_theme_color_override(&"font_hover_color", font_hovered_color)
	tab.add_theme_color_override(&"font_pressed_color", font_selected_color)

func update_icon_color(tab: CustomTab, color: Color):
	tab.add_theme_color_override(&"icon_normal_color", color)
	tab.add_theme_color_override(&"icon_hover_color", color)
	tab.add_theme_color_override(&"icon_hover_pressed_color", color)
	tab.add_theme_color_override(&"icon_pressed_color", color)
	tab.add_theme_color_override(&"icon_focus_color", color)


func on_tab_right_click(tab: CustomTab):
	var index: int = tab.item_index
	suppress_temperature()
	scripts_item_list.item_clicked.emit(index, scripts_item_list.get_local_mouse_position(), MOUSE_BUTTON_RIGHT)

func on_new_tab_selected(tab: CustomTab):
	# Hide and show close button.
	if (!show_close_button_always):
		if (current_tab != null):
			current_tab.hide_close_button()

		if (tab != null):
			tab.show_close_button()

	update_script_text_filter()

	var index: int = tab.item_index
	if (scripts_item_list != null && !scripts_item_list.is_selected(index)):
		scripts_item_list.select(index)
		scripts_item_list.item_selected.emit(index)
		scripts_item_list.ensure_current_is_visible()

	# Remove spacing from previous tab.
	if (!show_close_button_always && current_tab != null):
		update_tab(current_tab)
	current_tab = tab

## Removes the script filter text and emits the signal so that the tabs stay
## and we do not break anything there.
func update_script_text_filter():
	if (script_filter_txt.text != &""):
		script_filter_txt.text = &""
		script_filter_txt.text_changed.emit(&"")

func on_tab_close_pressed(tab: CustomTab) -> void:
	tab_select_times.erase(tab.item_index)
	suppress_temperature()
	scripts_item_list.item_clicked.emit(tab.item_index, scripts_item_list.get_local_mouse_position(), MOUSE_BUTTON_MIDDLE)

func sync_tabs_with_item_list() -> void:
	if (plugin == null):
		return

	# Build a lookup of current ItemList entries by tooltip (script path).
	var item_by_tooltip: Dictionary = {}
	for index: int in scripts_item_list.item_count:
		var tooltip: String = scripts_item_list.get_item_tooltip(index)
		item_by_tooltip[tooltip] = index

	# Match existing tabs to their new item indices via tooltip.
	# Remove tabs that no longer have a matching item.
	var matched_indices: Dictionary = {}
	for i: int in range(get_tab_count() - 1, -1, -1):
		var tab: CustomTab = get_tab(i)
		var new_index: Variant = item_by_tooltip.get(tab.tooltip_text, null)

		if (new_index == null):
			# Script was removed.
			if (tab == current_tab):
				current_tab = null

			# Migrate select time to new index if needed, or erase.
			tab_select_times.erase(tab.item_index)
			multiline_tab_bar.remove_child(tab)
			free_tab(tab)
		else:
			# Remap the tab's item_index and select time.
			var old_index: int = tab.item_index
			if (old_index != new_index):
				if (tab_select_times.has(old_index)):
					tab_select_times[new_index] = tab_select_times[old_index]
					tab_select_times.erase(old_index)
				tab.item_index = new_index

			matched_indices[new_index] = tab

	# Add tabs for any new items that don't have a tab yet.
	for index: int in scripts_item_list.item_count:
		var tab: CustomTab = matched_indices.get(index, null)
		if (tab == null):
			tab = add_tab(index)

		update_tab(tab)

	sort_tabs_by_temperature()
	update_singleline_min_width()

## Sort tab children so most-recently-selected tabs appear first.
## Tabs with the same temperature are kept in item_index order for stability.
func sort_tabs_by_temperature():
	var tabs: Array[Node] = get_tabs()
	if (tabs.size() <= 1):
		return

	tabs.sort_custom(func(a: CustomTab, b: CustomTab) -> bool:
		var time_a: int = tab_select_times.get(a.item_index, 0)
		var time_b: int = tab_select_times.get(b.item_index, 0)
		if (time_a != time_b):
			return time_a > time_b
		return a.item_index < b.item_index
	)

	for i: int in tabs.size():
		multiline_tab_bar.move_child(tabs[i], i)

func tab_changed():
	update_script_text_filter()

	# When the tab change was not triggered by our component,
	# we need to sync the selection.
	var item_index: int = scripts_tab_container.current_tab
	var tab: CustomTab = find_tab_by_item_index(item_index)

	# Only update temperature for direct tab changes (not cycling, right-click, or close).
	var is_right_click: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if (!is_cycling_tabs && !is_temperature_suppressed() && !is_right_click):
		tab_select_times[item_index] = Time.get_ticks_msec()
		sort_tabs_by_temperature()
		update_singleline_min_width()
		if (is_singleline_tabs && scroll_container != null):
			scroll_to_start(true)

	update_tab(tab)

func script_order_changed() -> void:
	schedule_update()

func set_popup(new_popup: PopupPanel) -> void:
	popup = new_popup

func show_popup() -> void:
	if (popup == null):
		return

	scripts_item_list.get_parent().reparent(popup)
	scripts_item_list.get_parent().visible = true

	popup.size = Vector2(250 * get_editor_scale(), get_parent().size.y - size.y)
	popup.position = popup_btn.get_screen_position() - Vector2(popup.size.x, 0)
	popup.popup()

	script_filter_txt.grab_focus()

func get_editor_scale() -> float:
	return EditorInterface.get_editor_scale()

func set_show_close_button_always(new_value: bool):
	if (show_close_button_always == new_value):
		return

	show_close_button_always = new_value

	if (multiline_tab_bar == null):
		return

	for tab: CustomTab in get_tabs():
		tab.text = scripts_item_list.get_item_text(tab.item_index)
		if (show_close_button_always):
			tab.text += CLOSE_BTN_SPACER
			if (!tab.button_pressed):
				tab.show_close_button()
		else:
			if (!tab.button_pressed):
				tab.hide_close_button()
			else:
				tab.text += CLOSE_BTN_SPACER

func free_tabs():
	drag_marker.free()
	for tab: CustomTab in get_tabs():
		free_tab(tab)

func free_tab(tab: CustomTab):
	if (tab.close_button != null):
		tab.close_button.free()
	tab.free()

#region Singleline handling
var scroll_container: ScrollContainer
var scroll_tween: Tween

func set_singleline_tabs(new_value: bool):
	if (is_singleline_tabs == new_value):
		return

	is_singleline_tabs = new_value

	if (multiline_tab_bar == null):
		return

	if (is_singleline_tabs):
		enable_singleline()
	else:
		disable_singleline()

func enable_singleline():
	# Create a ScrollContainer and reparent the tab bar into it.
	scroll_container = ScrollContainer.new()
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.follow_focus = false

	var parent: Node = multiline_tab_bar.get_parent()
	var tab_bar_index: int = multiline_tab_bar.get_index()

	parent.remove_child(multiline_tab_bar)
	parent.add_child(scroll_container)
	parent.move_child(scroll_container, tab_bar_index)

	scroll_container.add_child(multiline_tab_bar)

	# All tabs must be visible — scrolling handles overflow now.
	for tab: CustomTab in get_tabs():
		tab.visible = true

	# Force the HFlowContainer wide enough that it never wraps.
	update_singleline_min_width()

	tab_group.pressed.connect(on_singleline_tab_selected.unbind(1))
	scroll_to_tab(current_tab, false)

func disable_singleline():
	if (scroll_container == null):
		return

	tab_group.pressed.disconnect(on_singleline_tab_selected)

	# Reparent tab bar back out of the scroll container.
	var parent: Node = scroll_container.get_parent()
	var sc_index: int = scroll_container.get_index()

	scroll_container.remove_child(multiline_tab_bar)
	parent.add_child(multiline_tab_bar)
	parent.move_child(multiline_tab_bar, sc_index)

	parent.remove_child(scroll_container)
	scroll_container.queue_free()
	scroll_container = null

	# Reset min width so HFlowContainer can wrap again.
	multiline_tab_bar.custom_minimum_size.x = 0

	for tab: CustomTab in get_tabs():
		tab.visible = true

## Prevent wrapping immediately, then recalculate the real width after layout.
func update_singleline_min_width():
	if (!is_singleline_tabs):
		return

	# Phase 1: Set large value so HFlowContainer never wraps this frame.
	multiline_tab_bar.custom_minimum_size.x = 100000

	# Phase 2: After layout, shrink to actual content width.
	recalc_singleline_min_width.call_deferred()

func recalc_singleline_min_width():
	if (!is_singleline_tabs || multiline_tab_bar == null):
		return

	var total_width: float = 0.0
	for tab: CustomTab in get_tabs():
		total_width += tab.size.x

	# Add separation between tabs.
	var sep: float = multiline_tab_bar.get_theme_constant(&"h_separation") if multiline_tab_bar.has_theme_constant(&"h_separation") else 4
	var tab_count: int = get_tab_count()
	if (tab_count > 1):
		total_width += sep * (tab_count - 1)

	multiline_tab_bar.custom_minimum_size.x = total_width + 64

func on_singleline_tab_selected():
	scroll_to_tab(current_tab, true)

func scroll_to_start(animate: bool):
	if (scroll_container == null):
		return

	if (!animate || scroll_container.scroll_horizontal < 1):
		scroll_container.scroll_horizontal = 0
		return

	if (scroll_tween != null):
		scroll_tween.kill()

	scroll_tween = create_tween()
	scroll_tween.set_ease(Tween.EASE_OUT)
	scroll_tween.set_trans(Tween.TRANS_CUBIC)
	scroll_tween.tween_property(scroll_container, "scroll_horizontal", 0, 0.15)

func scroll_to_tab(tab: CustomTab, animate: bool):
	if (tab == null || scroll_container == null):
		return

	# Ensure all tabs are visible so positions are valid.
	for t: CustomTab in get_tabs():
		t.visible = true

	# Wait a frame for layout if needed.
	if (tab.size.x == 0):
		await get_tree().process_frame

	var peek_padding: float = 64.0 * EditorInterface.get_editor_scale()
	var tab_left: float = tab.position.x
	var tab_right: float = tab_left + tab.size.x
	var viewport_width: float = scroll_container.size.x
	var current_scroll: float = scroll_container.scroll_horizontal
	var max_scroll: float = multiline_tab_bar.size.x - viewport_width

	var target_scroll: float = current_scroll

	# If tab is to the right of the visible area, scroll right with peek room.
	if (tab_right + peek_padding > current_scroll + viewport_width):
		target_scroll = tab_right + peek_padding - viewport_width

	# If tab is to the left of the visible area, scroll left with peek room.
	if (tab_left - peek_padding < current_scroll):
		target_scroll = tab_left - peek_padding

	target_scroll = clampf(target_scroll, 0, max(max_scroll, 0))

	if (!animate || absf(target_scroll - current_scroll) < 1.0):
		scroll_container.scroll_horizontal = int(target_scroll)
		return

	if (scroll_tween != null):
		scroll_tween.kill()

	scroll_tween = create_tween()
	scroll_tween.set_ease(Tween.EASE_OUT)
	scroll_tween.set_trans(Tween.TRANS_CUBIC)
	scroll_tween.tween_property(scroll_container, "scroll_horizontal", int(target_scroll), 0.15)
#endregion
