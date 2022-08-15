# Godot Laigter Tools

Plugin to simplify workflow with the Laigter PBR map generator tool.

Requires Laigter by Azagaya: [Github](https://github.com/azagaya/laigter) | [Itch](https://azagaya.itch.io/laigter)

The Project Setting `laigter/LAIGTER_BINARY_PATH` will be created when the plugin is used, set this to the Laigter binary/executable if installed portably or the default setting doesn't work.

![Preview screenshot of the LaigterTools plugin](https://i.imgur.com/ImKNB9c.png)

Current features are unfinished, untested and minimal.

* Drag a texture resource from the filesystem in Godot, onto the image drop target in the plugin panel.
* Select the maps you want to generate from the checkboxes (normal, specular, occlusion, parallax/depth)
* Select a preset to apply 
  * A simple default preset is included
  * Export presets from Laigter's preset menu to the `addons/laigter_tools/laigter_presets` folder and reload the plugin/godot
* Choose whether to open the Laigter GUI or not (if you want to tweak values).
* Changes to the temporary textures will be detected and reloaded, e.g. when exporting from the Laigter GUI or making external changes in an image editor.
* Hit "Save" to save the textures alongside the original texture in the filesystem.
