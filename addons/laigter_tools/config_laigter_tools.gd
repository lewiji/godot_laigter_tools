tool
extends Resource
class_name LaigterToolsConfig
# General config keys and paths
const config_section_id = "laigter"
const laigter_default_path = {"X11": "/usr/bin/laigter"}
const temp_config_path = "user://laigter.tmp"
const temp_image_path = "user://cache/"

# config keys for configurable settings
enum ConfigKeys { 
	GENERATE_NORMAL_MAP = 0, 
	GENERATE_SPECULAR = 1, 
	GENERATE_OCCLUSION = 2, 
	GENERATE_PARALLAX = 3, 
	LAIGTER_BINARY_PATH = 4
}

# config values
static func get_config_defaults():
	return {
		ConfigKeys.GENERATE_NORMAL_MAP: { "type": TYPE_BOOL, "default": true, "cli_flag": "-n" }, 
		ConfigKeys.GENERATE_SPECULAR: { "type": TYPE_BOOL, "default": true, "cli_flag": "-c"  }, 
		ConfigKeys.GENERATE_OCCLUSION: { "type": TYPE_BOOL, "default": true, "cli_flag": "-o"  }, 
		ConfigKeys.GENERATE_PARALLAX: { "type": TYPE_BOOL, "default": true, "cli_flag": "-p"  }, 
		ConfigKeys.LAIGTER_BINARY_PATH: { 
			"type": TYPE_STRING, 
			"hint": PROPERTY_HINT_GLOBAL_FILE,
			"default": laigter_default_path[OS.get_name()] 
		}
	}

static func get_cache_path(dir):
	return "%s/%s" % [OS.get_user_data_dir(), dir]

# get full project settings key
static func get_qualified_setting_name(setting: int) -> String:
	return "%s/%s" % [config_section_id, ConfigKeys.keys()[setting]]

# returns configuration value from specified ConfigKeys enum
static func get_config_value(config_key: int):
	return ProjectSettings.get_setting(get_qualified_setting_name(config_key))
	
static func set_config_value(config_key: int, value):
	ProjectSettings.set_setting(get_qualified_setting_name(config_key), value)

# initialise new/load existing temp cfg, return the initialised ConfigFile
static func _load_tmp_config_file():
	var config = ConfigFile.new()
	var err = config.load(temp_config_path)
	return config

# get a saved value from the temp ConfigFile
static func get_temp_config_value(key: String):
	var cfg: ConfigFile = _load_tmp_config_file()
	if (cfg != null and cfg.has_section_key(config_section_id, key)):
	  return cfg.get_value(config_section_id, key)
	
# assign a key/value pair to the temp ConfigFile, and save to disk
static func set_temp_config_value(key: String, value):
	var cfg: ConfigFile = _load_tmp_config_file()
	if (cfg != null):
	  cfg.set_value(config_section_id, key, value)
	  cfg.save(temp_config_path)
	  
# erase tmp config
static func clear_temp_config_file():
	var config: ConfigFile = _load_tmp_config_file()
	if (config != null):
	  config.clear()
	  config.save(temp_config_path)
