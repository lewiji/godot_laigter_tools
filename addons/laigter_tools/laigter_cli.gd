extends Node
class_name LaigterCli

# cli flags - `laigter --help` output is pasted at the bottom for reference
const CONFIG_KEYS_CLI = {
	LaigterToolsConfig.ConfigKeys.GENERATE_NORMAL_MAP: "-n",
	LaigterToolsConfig.ConfigKeys.GENERATE_OCCLUSION: "-o", 
	LaigterToolsConfig.ConfigKeys.GENERATE_PARALLAX: "-p", 
	LaigterToolsConfig.ConfigKeys.GENERATE_SPECULAR: "-c"
}

const os_command = {
	"Windows": { 
		"console": "cmd.exe", 
		"flag": "/c"
	}, 
	"X11": {
		"console": "/usr/bin/bash", 
		"flag": "-c"
	}}

# get a string representing the optional flags to pass to the laigter binary from settings
static func get_cmd_flags() -> String:
	var flags = PoolStringArray()
	for setting_idx in CONFIG_KEYS_CLI:
		if LaigterToolsConfig.get_config_value(setting_idx):
			flags.append(CONFIG_KEYS_CLI[setting_idx])
	return flags.join(" ")

# execute a process
static func execute_cmd(cmd: String, block = true) -> int:
	var native = os_command[OS.get_name()]
	var output = []
	print("%s %s %s" % [native.console, native.flag, cmd])
	var exit_code = OS.execute(native.console, [native.flag, cmd], block, output, true)
	if (exit_code != 0):
		print("Process exited with code: %d" % exit_code)
	for line in output:
		print(line)
	return exit_code

# given a Resource, get the full OS file path from the res:// path
static func get_absolute_resource_path(res_path: String):
	var filesystem = File.new()
	var err = filesystem.open(res_path, File.READ)
	filesystem.call_deferred("close")
	filesystem.call_deferred("free")
	
	if (err != OK):
		print("%s: Failed load resource from %s" % [err, res_path])
		return null
	
	var abs_path = filesystem.get_path_absolute()
	if (OS.get_name() == "X11"):
		abs_path = "'%s'" % abs_path
	return abs_path

static func execute_laigter(input_texture: Texture) -> LaigterCliResult:
	var result_obj = LaigterCliResult.new()
	if (input_texture != null):
		result_obj.file_hash = input_texture.resource_path.hash()
		result_obj.cache_dir = LaigterToolsConfig.get_cache_path(result_obj.file_hash)
		result_obj.cache_file_path = "%s/%s" % [result_obj.cache_dir, input_texture.resource_path.get_file()]
		result_obj.input_file = input_texture.resource_path
		var dir = Directory.new()		
		assert(dir.file_exists(input_texture.resource_path), "failed find source texture at %s" % input_texture.resource_path)
		assert(dir.dir_exists(result_obj.cache_dir) or dir.make_dir_recursive(result_obj.cache_dir) == OK, "failed to create cache dir: %s" % result_obj.cache_dir)
		assert(dir.copy(input_texture.resource_path, result_obj.cache_file_path) == OK, "failed to copy texture resource to tmp user:// dir")
		print("copying '%s' from\n'%s' to '%s'" % [input_texture.resource_path.get_file(), input_texture.resource_path.get_base_dir(), result_obj.cache_file_path])
		
		result_obj.exit_code = execute_cmd("%s --no-gui %s -d %s" % [LaigterToolsConfig.get_config_value(LaigterToolsConfig.ConfigKeys.LAIGTER_BINARY_PATH), get_cmd_flags(), get_absolute_resource_path(result_obj.cache_file_path)])
	return result_obj

#	└─▪ laigter --help
#	Usage: laigter [options]
#	Test helper
#
#	Options:
#	-h, --help									 Displays help on commandline options.
#	--help-all									 Displays help including Qt specific
#	options.
#	-v, --version								 Displays version information.
#	-s, --software-opengl						Use software opengl renderer.
#	-g, --no-gui									do not start graphical interface
#	-d, --diffuse <diffuse texture path>	diffuse texture to load
#	-n, --normal									generate normals
#	-c, --specular								generate specular
#	-o, --occlusion								generate occlusion
#	-p, --parallax								generate parallax
#	-r, --preset <preset file path>		 presset to load
