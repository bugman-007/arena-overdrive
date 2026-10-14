class_name InputSetup
extends RefCounted
## Registers default key bindings at runtime so the project has no editor-only setup.

const BINDINGS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"dash": [KEY_SHIFT, KEY_SPACE],
	"attack": [KEY_J, KEY_K],
	"restart": [KEY_R, KEY_ENTER],
}


static func ensure_actions() -> void:
	for action: String in BINDINGS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for keycode: Key in BINDINGS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = keycode
			InputMap.action_add_event(action, ev)
	if InputMap.action_get_events("attack").size() == 2:
		var mouse := InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("attack", mouse)
