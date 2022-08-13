tool
extends Control
# Signals
signal on_images_generated(cli_result)

# Options controls
onready var normal_check: CheckButton = get_node("%NormalCheck")
onready var specular_check: CheckButton = get_node("%SpecularCheck")
onready var occlusion_check: CheckButton = get_node("%OcclusionCheck")
onready var parallax_check: CheckButton = get_node("%ParallaxCheck")
onready var preset_menu: MenuButton = get_node("%PresetMenu")
# Laigter preset load dialog
onready var file_dialog: FileDialog = get_node("%FileDialog")
# Drag & Drop/Image Preview Controls
onready var image_panel: Panel = get_node("%Panel")
onready var image_preview: TextureRect = get_node("%ImagePreview")
onready var drop_target: Control = get_node("%DropContainer")
# Generate button
onready var generate_button: Button = get_node("%GenerateMaps")

# The Texture resource to be used as input to Laigter
var input_texture: Texture
var image_file_extensions = ResourceLoader.get_recognized_extensions_for_type("Image")

onready var settings_buttons = {
	LaigterToolsConfig.ConfigKeys.GENERATE_NORMAL_MAP: normal_check, 
	LaigterToolsConfig.ConfigKeys.GENERATE_SPECULAR: specular_check, 
	LaigterToolsConfig.ConfigKeys.GENERATE_OCCLUSION: occlusion_check, 
	LaigterToolsConfig.ConfigKeys.GENERATE_PARALLAX: parallax_check
}

func _ready():
	setup_options()
	generate_button.connect("pressed", self, "on_generate_pressed")

func setup_options():
	for setting_idx in settings_buttons:
		settings_buttons[setting_idx].pressed = LaigterToolsConfig.get_config_value(setting_idx)
		settings_buttons[setting_idx].connect("toggled", self, "on_pref_toggled", [setting_idx])

func on_generate_pressed():
	var result = LaigterCli.execute_laigter(input_texture)
	if (result.exit_code == 0):
		 emit_signal("on_images_generated", result)
	
func on_pref_toggled(button_pressed: bool, setting_idx: int):
	LaigterToolsConfig.set_config_value(setting_idx, button_pressed)

# tell godot we accept drag and drop operations, validate the type of data 
# dropped is supported and check the drop was over our drop zone
func can_drop_data(position: Vector2, data):
	var valid_file = typeof(data) == TYPE_DICTIONARY and data["type"] == "files"
	var over_texture_panel = drop_target.get_rect().has_point(position);
	# visual effect on hover with valid data (darken on hover)
	image_panel.get_stylebox("panel").shadow_size = 1 if valid_file and over_texture_panel else 0			
	return valid_file and over_texture_panel

# handle dropped data - we've got a file. check we can handle it, and then set 
# it as our input image
func drop_data(position, data):
	image_panel.get_stylebox("panel").shadow_size = 0
	var files: Array = data["files"]
	for file in files:
		if image_file_extensions.has(file.get_extension()) and ResourceLoader.exists(file):
		 set_input_image(file)

func set_input_image(path: String):
	input_texture = load(path)
	image_preview.texture = input_texture
	if image_preview.texture != null:
		image_panel.get_node("Label").visible = false
	else:
		image_panel.get_node("Label").visible = true
