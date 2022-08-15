tool
extends Control

signal on_images_saved

var textures = []
var imported_textures = []
var cli_result: LaigterCliResult
var scan_changes_timer: Timer
var modified_times: Dictionary
onready var grid: GridContainer = get_node("%PreviewGrid")
onready var checkbox_orig_dir: CheckBox = get_node("%CheckOriginalDir")
onready var btn_save: Button = get_node("%SaveImages")

func _ready():
	btn_save.connect("pressed", self, "on_save_requested")
	
func on_images_generated(result: LaigterCliResult):
	cli_result = result
	
	if(scan_changes_timer != null and scan_changes_timer.is_inside_tree()):
		remove_child(scan_changes_timer)
		scan_changes_timer.free()
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
	var dir_path = cli_result.cache_dir
	var dir = Directory.new()
	dir.open(dir_path)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if !dir.current_is_dir():
			textures.append("%s/%s" % [dir_path, file_name])
		file_name = dir.get_next()

func on_save_requested():
	assert(cli_result != null, "No Laigter results object found, couldn't save")
	for texture in imported_textures:
		ResourceSaver.save("%s/%s" % [cli_result.input_file.get_base_dir(), texture.resource_name], texture)
	emit_signal("on_images_saved")

func load_preview_images_from_dir(cli_result: LaigterCliResult):
	var dir_path = cli_result.cache_dir
	var dir = Directory.new()
	if (!dir.dir_exists(dir_path)):
		print("No directory: " + dir_path)
		return
	
	if (dir.open(dir_path) != OK):
		print("No open directory: " + dir_path)
		return
		
	if (dir.list_dir_begin() != OK):
		print("Coudln't list: " + dir_path)
		return
	var file_name = dir.get_next()
	
	while file_name != "":
		if !dir.current_is_dir():
			print("Found file: " + file_name)
			textures.append("%s/%s" % [dir_path, file_name])
		file_name = dir.get_next()
	
	scan_changes_timer.start(1)
	
	var lit_preview = preload("preview_lit.tscn").instance()
	var mat = lit_preview.get_node("%PreviewSpatial/MeshInstance").material_override as SpatialMaterial
	
	for tex_path in textures:
		var file = File.new()
		if file.open(tex_path, File.READ) != OK:
			print("couldn't open file at %s" % tex_path)
			return
		var filename = tex_path.get_slice("/", tex_path.count("/"))
		modified_times[filename] = file.get_modified_time(filename)
		var tex = ImageTexture.new()
		tex.resource_name = filename
		var img = Image.new()
		
		img.load(tex_path)		
		img.generate_mipmaps()		
		tex.create_from_image(img, Texture.FLAG_ANISOTROPIC_FILTER | Texture.FLAG_MIPMAPS)
		imported_textures.append(tex)
		
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

	grid.add_child(lit_preview)
	yield(get_tree(), "idle_frame")
	lit_preview.get_node("%PreviewSpatial/AnimationPlayer").play("spin")
	
