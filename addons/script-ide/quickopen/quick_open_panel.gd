## Quick open panel to quickly access all resources that are in the project.
## Initially shows all resources, but can be changed to more specific resources
## or filtered down with text.
@tool
extends PopupPanel

const ADDONS: StringName = &"res://addons"
const ALLOWED_ADDONS: Array[StringName] = [&"res://addons/asset-plugin", &"res://addons/beatmap-plugin"]
const SEPARATOR: StringName = &" - "
const STRUCTURE_START: StringName = &"("
const STRUCTURE_END: StringName = &")"

#region UI
@onready var filter_bar: TabBar = %FilterBar
@onready var search_option_btn: OptionButton = %SearchOptionBtn
@onready var filter_txt: LineEdit = %FilterTxt
@onready var files_list: ItemList = %FilesList
#endregion

var plugin: EditorPlugin

var scenes: Array[FileData]
var scripts: Array[FileData]
var resources: Array[FileData]
var others: Array[FileData]

# For performance and memory considerations, we add all files into one reusable array.
var all_files: Array[FileData]

var is_rebuild_cache: bool = true

#region Plugin and Shortcut processing
func _ready() -> void:
	files_list.item_selected.connect(open_file)
	search_option_btn.item_selected.connect(rebuild_cache_and_ui.unbind(1))
	filter_txt.text_changed.connect(fill_files_list.unbind(1))

	filter_bar.tab_changed.connect(change_fill_files_list.unbind(1))

	about_to_popup.connect(on_show)

	var file_system: EditorFileSystem = EditorInterface.get_resource_filesystem()
	file_system.filesystem_changed.connect(schedule_rebuild)

	if (plugin != null):
		filter_txt.gui_input.connect(plugin.navigate_on_list.bind(files_list, open_file))

func _shortcut_input(event: InputEvent) -> void:
	if (!event.is_pressed() || event.is_echo()):
		return

	if (plugin.tab_cycle_forward_shc.matches_event(event)):
		get_viewport().set_input_as_handled()

		var new_tab: int = filter_bar.current_tab + 1
		if (new_tab == filter_bar.get_tab_count()):
			new_tab = 0
		filter_bar.current_tab = new_tab
	elif (plugin.tab_cycle_backward_shc.matches_event(event)):
		get_viewport().set_input_as_handled()

		var new_tab: int = filter_bar.current_tab - 1
		if (new_tab == -1):
			new_tab = filter_bar.get_tab_count() - 1
		filter_bar.current_tab = new_tab
#endregion

func open_file(index: int):
	var file: String = files_list.get_item_metadata(index)

	if (ResourceLoader.exists(file)):
		var res: Resource = load(file)

		if (res is Script):
			EditorInterface.edit_script(res)
			EditorInterface.set_main_screen_editor.call_deferred("Script")
		else:
			EditorInterface.edit_resource(res)

		if (res is PackedScene):
			EditorInterface.open_scene_from_path(file)

			# Need to be deferred as it does not work otherwise.
			var root: Node = EditorInterface.get_edited_scene_root()
			if (root is Node3D):
				EditorInterface.set_main_screen_editor.call_deferred("3D")
			else:
				EditorInterface.set_main_screen_editor.call_deferred("2D")
	else:
		# Text files (.txt, .md) will not be recognized, which seems to be a very bad
		# limitation from the Engine. The methods called by the Engine are also not exposed.
		# So we just select the file, which is better than nothing.
		EditorInterface.select_file(file)

	# Deferred as otherwise we get weird errors in the console.
	# Probably due to this beeing called in a signal and auto unparent is true.
	# 100% Engine bug or at least weird behavior.
	hide.call_deferred()

func schedule_rebuild():
	is_rebuild_cache = true

func on_show():
	if (search_option_btn.selected != 0):
		search_option_btn.selected = 0

		is_rebuild_cache = true

	var rebuild_ui: bool = false
	var all_tab_not_pressed: bool = filter_bar.current_tab != 0
	rebuild_ui = is_rebuild_cache || all_tab_not_pressed

	if (is_rebuild_cache):
		rebuild_cache()

	if (rebuild_ui):
		if (all_tab_not_pressed):
			# Triggers the ui update.
			filter_bar.current_tab = 0
		else:
			fill_files_list()

	filter_txt.select_all()
	focus_and_select_first()

func rebuild_cache():
	is_rebuild_cache = false

	all_files.clear()
	scenes.clear()
	scripts.clear()
	resources.clear()
	others.clear()

	build_file_cache()

func rebuild_cache_and_ui():
	rebuild_cache()
	fill_files_list()

	focus_and_select_first()

func focus_and_select_first():
	filter_txt.grab_focus()

	if (files_list.item_count > 0):
		files_list.select(0)

func build_file_cache():
	var dir: EditorFileSystemDirectory = EditorInterface.get_resource_filesystem().get_filesystem()
	build_file_cache_dir(dir)

	all_files.append_array(scenes)
	all_files.append_array(scripts)
	all_files.append_array(resources)
	all_files.append_array(others)

func build_file_cache_dir(dir: EditorFileSystemDirectory):
	for index: int in dir.get_subdir_count():
		build_file_cache_dir(dir.get_subdir(index))

	for index: int in dir.get_file_count():
		var file: String = dir.get_file_path(index)
		if (search_option_btn.get_selected_id() == 0 && file.begins_with(ADDONS)):
			var is_allowed_addon := ALLOWED_ADDONS.any(func(addon) -> bool:
				return file.begins_with(addon)
			)
			if not is_allowed_addon:
				continue

		var last_delimiter: int = file.rfind(&"/")

		var file_name: String = file.substr(last_delimiter + 1)
		var file_structure: String = &""
		if (file_name.length() + 6 != file.length()):
			file_structure = SEPARATOR + STRUCTURE_START + file.substr(6, last_delimiter - 6) + STRUCTURE_END

		var file_data: FileData = FileData.new()
		file_data.file = file
		file_data.file_name = file_name
		file_data.file_name_structure = file_name + file_structure
		file_data.file_type = dir.get_file_type(index)

		# Needed, as otherwise we have no icon.
		if (file_data.file_type == &"Resource"):
			file_data.file_type = &"Object"

		match (file.get_extension()):
			&"tscn": scenes.append(file_data)
			&"gd": scripts.append(file_data)
			&"tres": resources.append(file_data)
			&"gdshader": resources.append(file_data)
			_: others.append(file_data)

func change_fill_files_list():
	fill_files_list()

	focus_and_select_first()

func fill_files_list():
	files_list.clear()

	if (filter_bar.current_tab == 0):
		fill_files_list_with(all_files)
	elif (filter_bar.current_tab == 1):
		fill_files_list_with(scenes)
	elif (filter_bar.current_tab == 2):
		fill_files_list_with(scripts)
	elif (filter_bar.current_tab == 3):
		fill_files_list_with(resources)
	elif (filter_bar.current_tab == 4):
		fill_files_list_with(others)

func fill_files_list_with(files: Array[FileData]):
	var filter_text: String = filter_txt.text

	if (filter_text.is_empty()):
		for file_data: FileData in files:
			add_file_item(file_data)
		return

	var query_lower: String = filter_text.to_lower()
	var scored: Array = []
	for file_data: FileData in files:
		var score: int = compute_match_score(query_lower, file_data)
		if (score >= 0):
			scored.append([score, file_data])

	scored.sort_custom(func(a, b) -> bool:
		if (a[0] != b[0]):
			return a[0] > b[0]
		return a[1].file_name < b[1].file_name
	)

	for entry: Array in scored:
		add_file_item(entry[1])

func add_file_item(file_data: FileData):
	var icon: Texture2D = EditorInterface.get_base_control().get_theme_icon(file_data.file_type, &"EditorIcons")
	files_list.add_item(file_data.file_name_structure, icon)
	files_list.set_item_metadata(files_list.item_count - 1, file_data.file)
	files_list.set_item_tooltip(files_list.item_count - 1, file_data.file)

# Tiered so any file_name hit outranks any path-only hit, and substring beats subsequence.
func compute_match_score(query_lower: String, file_data: FileData) -> int:
	var name_lower: String = file_data.file_name.to_lower()

	var name_substr: int = name_lower.find(query_lower)
	if (name_substr >= 0):
		return 1000000 - name_substr * 1000 - file_data.file_name.length()

	var name_score: int = fuzzy_subseq_score(query_lower, name_lower, file_data.file_name)
	if (name_score >= 0):
		return 500000 + name_score - file_data.file_name.length()

	var path_lower: String = file_data.file.to_lower()
	var path_substr: int = path_lower.find(query_lower)
	if (path_substr >= 0):
		return 100000 - path_substr

	var path_score: int = fuzzy_subseq_score(query_lower, path_lower, file_data.file)
	if (path_score >= 0):
		return path_score

	return -1

func fuzzy_subseq_score(query_lower: String, target_lower: String, target_original: String) -> int:
	var score: int = 0
	var q_idx: int = 0
	var last_match: int = -2
	for i: int in target_lower.length():
		if (q_idx >= query_lower.length()):
			break
		if (target_lower[i] == query_lower[q_idx]):
			score += 10
			if (last_match == i - 1):
				score += 15
			if (i == 0):
				score += 20
			else:
				var prev: String = target_original[i - 1]
				if (prev == "_" || prev == "/" || prev == "-" || prev == "."):
					score += 15
				else:
					var cur: String = target_original[i]
					if (cur != cur.to_lower() && prev == prev.to_lower()):
						score += 10
			last_match = i
			q_idx += 1

	if (q_idx < query_lower.length()):
		return -1

	return score

class FileData:
	var file: String
	var file_name: String
	var file_name_structure: String
	var file_type: StringName
