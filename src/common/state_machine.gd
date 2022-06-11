class_name StateMachine
extends Node

signal transitioned(sender, new_state, old_state)

export var initial_state_path := NodePath()

var state = null
var state_name = null

func _ready():
	yield(owner, "ready")
	if (initial_state_path.is_empty()):
		printerr("No initial state specified")
		state = get_child(0)
	else:
		state = get_node(initial_state_path)

	state_name = state.name

	for child in get_children():
		child.state_machine = self
	state.enter()


func _unhandled_input(event):
	state.handle_input(event)


func _process(delta):
	state.update(delta)


func _physics_process(delta):
	state.physics_update(delta)


func transition(to: String, msg := {}) -> void:
	if not has_node(to):
		printerr("Can't transition to ", to)
		return
	
	var old_state = state
	state.exit()
	state_name = to
	state = get_node(to)
	state.enter(msg)
	emit_signal("transitioned", self, state, old_state)
