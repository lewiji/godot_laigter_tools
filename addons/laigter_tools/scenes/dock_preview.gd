tool
extends Control

signal on_images_saved
signal on_reset

var textures = []
var imported_textures = {}
var cli_result: LaigterCliResult
var scan_changes_timer: Timer
var modified_times: Dictionary
onready var grid: GridContainer = get_node("%PreviewGrid")
onready var btn_save: Button = get_node("%SaveImages")
onready var btn_reset: Button = get_node("%Reset")

func _ready():
	btn_save.connect("pressed", self, "on_save_requested")
	btn_reset.connect("pressed", self, "on_reset_pressed")
	connect("visibility_changed", self, "on_visibility_changed")
	
func on_hide():
	if (scan_changes_timer != null and !scan_changes_timer.is_stopped()):
		scan_changes_timer.stop()
		
func on_visibility_changed():
	if is_visible_in_tree():
		if (scan_changes_timer != null and scan_changes_timer.is_stopped()):
			scan_changes_timer.start(2)
	else:
		if (scan_changes_timer != null and !scan_changes_timer.is_stopped()):
			scan_changes_timer.stop()
	
func on_images_generated(result: LaigterCliResult):
	cli_result = result
	
	if(scan_changes_timer != null and scan_changes_timer.is_inside_tree()):
		remove_child(scan_changes_timer)
		scan_changes_timer.queue_free()
	scan_changes_timer = Timer.new()
	add_child(scan_changes_timer)
	scan_changes_timer.connect("timeout", self, "on_scan_changes")
	
	var kids = grid.get_children()
	for kid in kids:
		grid.remove_child(kid)
		kid.free()
	textures.clear()
	imported_textures.clear()
	modified_times.clear()
	
	load_preview_images_from_dir(cli_result)
	EditorPlugin.new().make_bottom_panel_item_visible(self)

func on_scan_changes():
	if (cli_result == null):
		return
	var file = File.new()
	for tex_path in textures:
		tex_path = tex_path as String
		if file.open(tex_path, File.READ) != OK:
			continue
		var filename = tex_path.get_file()
		var last_modified = modified_times[filename]
		var modified = file.get_modified_time(tex_path)
		if (last_modified != modified):
			print("%s has changed" % [tex_path])
			modified_times[filename] = modified
			if (imported_textures.has(filename)):
				var img = Image.new()
				img.load(tex_path)
				img.generate_mipmaps()
				imported_textures[filename].create_from_image(img, Texture.FLAG_ANISOTROPIC_FILTER | Texture.FLAG_MIPMAPS)
				print("reloaded texture")
	file.close()

func on_save_requested():
	assert(cli_result != null, "No Laigter results object found, couldn't save")
	for texture in imported_textures:
		ResourceSaver.save("%s/%s" % [cli_result.input_file.get_base_dir(), texture.resource_name], imported_textures[texture])
	emit_signal("on_images_saved")
	
func on_reset_pressed():
	if(scan_changes_timer != null and scan_changes_timer.is_inside_tree()):
		scan_changes_timer.stop()
	var kids = grid.get_children()
	for kid in kids:
		grid.remove_child(kid)
		kid.free()
	textures.clear()
	imported_textures.clear()
	modified_times.clear()
	emit_signal("on_reset")
		
func load_preview_images_from_dir(cli_result: LaigterCliResult):
	var dir_path = cli_result.cache_dir
	var dir = Directory.new()	
	assert(dir.open(dir_path) == OK, "Couldn't open directory: " + dir_path)
	
	dir.list_dir_begin()
	var file_name = dir.get_next()		
	while file_name != "":
		if !dir.current_is_dir():
			textures.append("%s/%s" % [dir_path, file_name])
		file_name = dir.get_next()
	
	scan_changes_timer.start(2)
	
	var lit_preview = preload("preview_lit.tscn").instance()
	var mat = lit_preview.get_node("%PreviewSpatial/MeshInstance").material_override as SpatialMaterial
	var file = File.new()
	
	for tex_path in textures:
		tex_path = tex_path as String
		assert(file.open(tex_path, File.READ) == OK, "couldn't open file at %s" % tex_path)
		var tex = ImageTexture.new()
		var img = Image.new()
		
		var filename = tex_path.get_file()
		tex.resource_name = filename
		
		img.load(tex_path)
		img.generate_mipmaps()
		tex.create_from_image(img, Texture.FLAG_ANISOTROPIC_FILTER | Texture.FLAG_MIPMAPS)
		imported_textures[filename] = tex
		
		modified_times[filename] = file.get_modified_time(tex_path)
		
		var preview = preload("preview_image.tscn").instance()
		preview.get_node("%TextureRect").texture = tex
		preview.get_node("%FilePath").text = filename
		grid.add_child(preview)
		
		var file_no_extension = filename.get_slice(".", filename.count(".") - 1)
		var suffix = file_no_extension.get_slice("_", file_no_extension.count("_"))
		match (suffix):
			"n":
				 mat.normal_texture = tex
				 mat.normal_enabled = true
				 mat.normal_scale = 1
			"s":
				 mat.roughness_texture = tex
				 mat.roughness = 1
			"o":
				 mat.ao_texture = tex
				 mat.ao_enabled = 1
				 mat.ao_light_affect = 0.5
			"p":
				 mat.depth_texture = tex
				 mat.depth_enabled = true
				 mat.depth_deep_parallax = true
				 mat.depth_scale = 0.05
			_:
				mat.albedo_texture = tex

	file.close()
	dir.list_dir_end()
	grid.add_child(lit_preview)
	yield(get_tree(), "idle_frame")
	lit_preview.get_node("%PreviewSpatial/AnimationPlayer").play("spin")
	
