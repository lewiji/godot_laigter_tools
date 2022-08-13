tool
extends EditorPlugin

func get_plugin_name():
	return "laigter_tools"

const dock_cache_key = "dock_instance_ids"

# initialise user settings if needed, and load the dock PackedScene
func _enter_tree():
	initialise_settings()
	add_docks()

# rescan filesystem after laigter has outputted images to the project
func on_images_saved():
	get_editor_interface().get_resource_filesystem().scan()

# add dock scenes to the editor
func add_docks():
	# drag n drop target dock
	var dock_drag_drop = preload("scenes/dock_drag_drop.tscn").instance()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UR, dock_drag_drop)
	# generated images preview dock
	var dock_preview = preload("scenes/dock_preview.tscn").instance()
	add_control_to_bottom_panel(dock_preview, "LaigterTools Preview")
	# connect "generate" button
	dock_drag_drop.connect("on_images_generated", dock_preview, "on_images_generated")
	dock_preview.connect("on_images_saved", self, "on_images_saved")
	# save docks' instance ids to temp config
	LaigterToolsConfig.set_temp_config_value(dock_cache_key, 
		[dock_drag_drop.get_instance_id(), dock_preview.get_instance_id()])

# set some ProjectSettings up, if they don't exist
func initialise_settings():
	for setting in LaigterToolsConfig.ConfigKeys:
		var setting_id = LaigterToolsConfig.ConfigKeys[setting]
		var full_name = LaigterToolsConfig.get_qualified_setting_name(setting_id)
		var config: Dictionary = LaigterToolsConfig.get_config_defaults()[setting_id]
		
		if (ProjectSettings.has_setting(full_name) or config == null):
			continue
		
		ProjectSettings.set_setting(full_name, config["default"])
		ProjectSettings.set_initial_value(full_name, config["default"])
		ProjectSettings.add_property_info({ 
			"type": config["type"] if config.has("type") else null,
			"hint": config["hint"] if config.has("hint") else null, 
			"name": full_name 
		})
		ProjectSettings.save()

# cleanup
func _exit_tree():
	# retrieve saved temp config dock instance id if possible
	var dock_id = LaigterToolsConfig.get_temp_config_value(dock_cache_key)
	if dock_id == null:
		return
	
	for dock_instance_id in dock_id:
		var dockInstance = instance_from_id(int(dock_instance_id))
		if (is_instance_valid(dockInstance) and dockInstance is Control):
			match (dockInstance as Control).name:
				"LaigterDock":
					remove_control_from_docks(dockInstance)
				"LaigterPreviewDock":
					remove_control_from_bottom_panel(dockInstance)
			dockInstance.free()

	# it's too late for you now, instance id
	LaigterToolsConfig.set_temp_config_value(dock_cache_key, null)
