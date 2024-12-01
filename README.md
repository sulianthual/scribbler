<div align="center"><img src="game_icon.png"></div>

<h4>Scribbler</h4>

sul (2024), Plugin for Godot 4.2+.

A side dock to make basic drawings without leaving the Godot editor, useful for prototyping. Has basic and custom paint tools, supports drag and drop from any file/texture in editor (PNG only), onion skinning, sprite sheets, etc. Janky, minimal and tailored to drawing black outlines+fillings and shadows. Github reference: [https://github.com/sulianthual/scribbler](https://github.com/sulianthual/scribbler)

<h4>Installation</h4>

All you need is the folder "addons/scribbler" in your Godot project (with same path). Either 1) Download from [github](https://github.com/sulianthual/scribbler), then copy only addons/scribbler to addons/scribbler in your project (the rest is documentation and some demo, not needed). Or 2) download from Godot Asset Library, which should install only addons/scribbler. Version from Godot Asset Library may not be latest version, as I keep making changes on github.

Open your Godot project with Godot(4.2 or above), in Project Settings/Plugins enable the Scribbler Plugin. This will load the Scribbler side dock to bottom right. You can replace the dock anywhere (but dont "Make Floating"). 

<h4>Getting Started</h4>

Lets do a quick overview of features without details. Start a new drawing (press "menu" then "new").
Lets make a quick drawing to show an overview of features. 


<h4>Buttons</h4>

Press "+" in the menu to expand dock, when expanded press "-" to minimize again. Note: do not "Make Floating" the dock and expand/minimize altogether or the plugin will close. If the plugin closes disable/reenable it again in Project Settings/Plugins. Best practice is to not use "Make Floating".

Press "X" to hide the menu, press again to show. This is helpful if resizing the dock to a minimum (as buttons otherwise overlap).

Press "menu" to show/hide additional options (more later). Press "new" to make a new drawing.

