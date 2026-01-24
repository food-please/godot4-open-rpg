## A menu lists a [Battler]'s [member Battler.actions], allowing the player to select one.
class_name UIActionMenu extends VBoxContainer

## Emitted when a player has selected an action and the menu has faded to transparent.
signal action_selected(action: BattlerAction)

## Emitted whenever a new action is focused on the menu.
signal action_focused(action: BattlerAction)

## The scene representing the different menu entries. The scene must be some derivation of 
## [BaseButton].
@export var entry_scene: PackedScene

# The menu tracks the [BattlerAction]s available to a single [Battler], depending on Battler state 
# (energy costs, for example).
# The action menu also needs to respond to Battler state, such as a change in energy points or the
# Battler's health.
@export var _battler: Battler

# Refer to the BattlerRoster to check whether or not an action is valid when it is selected.
# This allows us to prevent the player from selecting an invalid action.
var _battler_roster: BattlerRoster

@onready var _menu_cursor: = $MenuCursor as UIMenuCursor


func _ready() -> void:
	hide()
	_menu_cursor.hide()
	set_process_unhandled_input(false)


# Capture any input events that will signal going "back" in the menu hierarchy.
# This includes mouse or touch input outside of a menu or pressing the back button/key.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("select") or event.is_action_released("back"):
		queue_free()
		CombatEvents.player_battler_selected.emit(null)


## Create the action menu, creating an entry for each [BattlerAction] (valid or otherwise) available
## to the selected [Battler].
## These actions are validated at run-time as they are selected in the menu.
func setup(selected_battler: Battler, battler_roster: BattlerRoster) -> void:
	_battler = selected_battler
	_battler_roster = battler_roster
	
	if _battler.actions.is_empty():
		action_selected.emit.call_deferred(null)
		return
	
	var first_button: UIActionButton
	var last_button: UIActionButton
	
	# Create the list of action entries, a series of buttons allowing the player to select actions.
	for action in _battler.actions:
		#var new_entry = _create_entry() as UIActionButton
		var new_entry: = entry_scene.instantiate()
		assert(new_entry is UIActionButton, "Entries to the UIActionMenu must be UIActionButtons!" + 
			" A non-UIActionButton entry_scene has been specified.")
		add_child(new_entry)
		
		new_entry.action = action
		new_entry.disabled = _battler.stats.energy < action.energy_cost
		#new_entry.focus_neighbor_right = "." # Don't allow input to jump to the player battler list.
		
		new_entry.focus_entered.connect(_on_entry_focused.bind(new_entry))
		new_entry.mouse_entered.connect(_on_entry_focused.bind(new_entry))
		new_entry.pressed.connect(_on_entry_pressed.bind(new_entry))
		
		last_button = new_entry
	
	# Find the first UIActionButton in the menu. Flag this as the first button.
	for button in get_children():
		if button is UIActionButton:
			first_button = button
			break
	
	# If the menu has more than one entry, link the top and bottom entries (e.g. pressing down while
	# on the bottom entry will cycle the menu selection to the topmost entry).
	if last_button != first_button:
		first_button.focus_neighbor_top = first_button.get_path_to(last_button)
		last_button.focus_neighbor_bottom = last_button.get_path_to(first_button)
	
	# Wait a frame for the menu elements to be setup...
	await get_tree().process_frame
	
	# ...then place the menu cursor - without tweening its position - at the first entry...
	first_button.grab_focus()
	_menu_cursor.position = first_button.global_position + Vector2(0.0, first_button.size.y/2.0)
	_menu_cursor.show()
	
	# ...and finally activate the menu for player input.
	show()
	set_process_unhandled_input(true)


# Moves the [UIMenuCursor] to the focused entry. Derivative menus may want to add additional
# behaviour.
func _on_entry_focused(entry: UIActionButton) -> void:
	_menu_cursor.move_to(entry.global_position + Vector2(0.0, entry.size.y/2.0))
	action_focused.emit(entry.action)


# Override the base method to allow the player to select an action for the specified Battler.
func _on_entry_pressed(entry: BaseButton) -> void:
	var action_entry: = entry as UIActionButton
	var action: BattlerAction = action_entry.action.duplicate()
	
	# First of all, check to make sure that the action has valid targets. If it does
	# not, do not allow selection of the action.
	if action.get_possible_targets(_battler, _battler_roster).is_empty():
		# Normally, the button gives up focus when selected (to stop cycling menu during animation).
		# However, the action is invalid and so the menu needs to keep focus for the player to
		# select another action.
		entry.grab_focus.call_deferred()
		return
	
	# There are available targets, so the UI can move on to selecting targets.
	queue_free()
	action_selected.emit(action)
