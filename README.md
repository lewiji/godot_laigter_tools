# Godot Laigter Tools

Plugin to simplify workflow with the Laigter PBR map generator tool.

Requires Laigter by Azagaya: [Github](https://github.com/azagaya/laigter) | [Itch](https://azagaya.itch.io/laigter)

The Project Setting `laigter/LAIGTER_BINARY_PATH` will be created when the plugin is used, set this to the Laigter binary/executable if installed portably or the default setting doesn't work.

https://user-images.githubusercontent.com/233380/184919559-1bc0b1fe-8dcc-431c-9f25-aecb77684eb6.mp4

Current features are unfinished, untested and minimal.

* Drag a texture resource from the filesystem in Godot, onto the image drop target in the plugin panel.
* Select the maps you want to generate from the checkboxes (normal, specular, occlusion, parallax/depth)
* Select a preset to apply 
  * A simple default preset is included
  * Export presets from Laigter's preset menu to the `addons/laigter_tools/laigter_presets` folder and reload the plugin/godot
* Choose whether to open the Laigter GUI or not (if you want to tweak values).
* Changes to the temporary textures will be detected and reloaded, e.g. when exporting from the Laigter GUI or making external changes in an image editor.
* Hit "Save" to save the textures alongside the original texture in the filesystem.
 * Check/uncheck "Save" next to a texture to select which textures to keep.
 * Check "Save" next to the 3D preview to also save a `SpatialMaterial` resource with the textures in the appropriate slots.
