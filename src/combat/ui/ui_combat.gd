## The combat UI coordinates player input during the combat game-state.
##
## The menus are largely signal driven, which are emitted according to player input. The player is
## responsible for issuing [BattlerAction]s to their respective [Battler]s, which are acted out in
## order by the [ActiveTurnQueue].[br][br]
##
## Actions are issued according to the following steps:[br]
##     - The player selects one of their Battlers from the [UIPlayerBattlerList].[br]
##     - A [UIActionMenu] appears, which allows the player to select a valid action.[br]
##     - Finally, potential targets are navigated using a [UIBattlerTargetingCursor].[br]
## The player may traverse the menus, going backwards and forwards through the menus as needed.
## Once the player has picked an action and targets, it is assigned to the queue by means of the
## [signal CombatEvents.action_selected] global signal.
class_name UICombat extends Control

## The action menu scene that will be created whenever the player needs to select an action.
@export var action_menu_scene: PackedScene

## The targetting cursor scene that will be created whenever the player needs to choose targets.
@export var target_cursor_scene: PackedScene

# The UI is responsible for relaying player input to the combat systems. In this case, we want to
# track which battler and action are currently selected, so that we may queue orders for all player
# battlers before executing them sequentially.
#var _selected_battler: Battler
	#set(value):
		#_selected_battler = value
		#if _selected_battler == null:
			#_selected_action = null

# Keep track of which action the player is currently building. This is relevent whenever the player
# is choosing targets.
#var _selected_action: BattlerAction = null

# A reference to the active action menu, which is created dynamically whenever the player chooses
# a BattlerAction.
# This reference is non-null only when the player is choosing an action.
#var _action_menu: UIActionMenu = null

# Keep reference to the active targeting cursor. If no cursor is active, the value is null.
# This allows the cursor targets to be updated in real-time as Battler states change.
#var _cursor: UIBattlerTargetingCursor = null

# UI elements - effects
@onready var animation: = $AnimationPlayer as AnimationPlayer
@onready var _effect_label_builder: = $EffectLabelBuilder as UIEffectLabelBuilder

# UI elements - player menus
@onready var _action_description: = $PlayerMenus/ActionDescription as UIActionDescription
@onready var _action_menu_anchor: = $PlayerMenus/ActionMenuAnchor as Control
@onready var _battler_list: = $PlayerMenus/PlayerBattlerList as UIPlayerBattlerList


## Prepare the menus for use by assigning appropriate [BattlerRoster] data.
func setup(battler_data: BattlerRoster) -> void:
	_effect_label_builder.setup(battler_data)
	_battler_list.battlers = battler_data.get_player_battlers()
	
	# If a player battler has been selected, the action menu should open so that the player may
	# choose an action.
	# If no battler is selected (i.e. it's time to execute the actions) then the menus will just be
	# hidden.
	CombatEvents.player_battler_selected.connect(
		(func _on_player_battler_selected(battler: Battler) -> void:
			if battler != null:
				print("Looking for actions: ", battler.actions)
				choose_action(battler)
			)
			
			# Player menu. choose actions(action_list)
			
			# Player menu.cancelled.connect(one shot).bind(selected_battler)
			# func on_cancelled:
			#	find previous battler (from selected battler)
			#	remove their cached action
			#	emit selected (null) signal. Combat engine should pick that up and recall _selecte_player_action
			
			# Player menus.action_selected.connect().bind(selected_battler)
			# func on_action_selected
			#	selected_battler.cached_action = selected_action
			
			# DONE. Don't need the combat UI to do any other coordinating.
			
			## Reset the action description bar.
			#_action_description.description = ""
			#
			#_selected_battler = battler
			#if _selected_battler:
				#_create_action_menu()
	)


func choose_action(battler: Battler) -> void:
	# Instantiate the scene, stuff it full of action data, and show it on the screen.
	var action_menu = action_menu_scene.instantiate() as UIActionMenu
	_action_menu_anchor.add_child(action_menu)
	action_menu.setup(battler.actions)
	action_menu.is_active = true
	
	# Link the action menu to the action description bar, providing a description of the
	# highlighted action.
	action_menu.action_focused.connect(
		func _on_action_focused(action: BattlerAction) -> void:
			_action_description.description = action.description
	)
	
	# The action builder will wait until the player selects an action or presses 'back'.
	# Selecting an action will trigger the following signal, whereas pressing 'back' will try to
	# return action selection to the previous player Battler.
	action_menu.action_selected.connect(
		(func _on_action_selected(action: BattlerAction, selected_battler: Battler) -> void:
			if action != null:
				choose_targets.call_deferred(selected_battler, action)
			
			# Cache a null action, indicating that the player refused selection and is looking to
			# choose actions for the previous Battler.
			else:
				selected_battler.cached_action = null

			## Whether or not the player selected an action, we'll want to hide the menu.
			action_menu.queue_free()
			).bind(battler)
	)


func choose_targets(battler: Battler, action: BattlerAction) -> void:
	# Create the cursor which will respond to player input and allow choosing a target.
	var cursor = target_cursor_scene.instantiate() as UIBattlerTargetingCursor
	cursor.targets_all = action.targets_all()
	cursor.targets = action.get_possible_targets()
	add_child(cursor)
	
	# The player may either select targets or press the "back" button.
	# If targets were chosen, we'll assign the targets to the action and, finally, cache the action
	# on the selected Battler.
	# If the user pressed "back", we'll go back to the choose action state.
	print("Choosing targets!")
	cursor.targets_selected.connect(
		(func _on_targets_selected(targets: Array[Battler], selected_action: BattlerAction,
				selected_battler: Battler) -> void:
			print("Found targets: ", targets)
			if not targets.is_empty():
				_action_description.description = ""
				
				selected_action.cached_targets = targets
				selected_battler.cached_action = selected_action
			
			else:
				choose_action(selected_battler)
			).bind(action, battler)
	)


#func _create_action_menu() -> void:
	#assert(_selected_battler, "Trying to create the action menu without a selected Battler!")
	#
	#var action_menu = action_menu_scene.instantiate() as UIActionMenu
	#_action_menu_anchor.add_child(action_menu)
	#action_menu.setup(_selected_battler.actions)
	#
	## Link the action menu to the action description bar, providing a description of the
	## highlighted action.
	#action_menu.action_focused.connect(
		#func _on_action_focused(action: BattlerAction) -> void:
			#_action_description.description = action.description
	#)
	#
	## The action builder will wait until the player selects an action or presses 'back'.
	## Selecting an action will trigger the following signal, whereas pressing 'back' will try to
	## return action selection to the previous player Battler.
	#action_menu.action_selected.connect(
		#func _on_action_selected(action: BattlerAction) -> void:
			#_selected_action = action
			#_create_targeting_cursor()
	#)
#
#
#func _create_targeting_cursor() -> void:
	#assert(_selected_action, "Trying to create the targeting cursor without a selected action!")
	#
	## Create the cursor which will respond to player input and allow choosing a target.
	#_cursor = target_cursor_scene.instantiate() as UIBattlerTargetingCursor
	#_cursor.targets_all = _selected_action.targets_all()
	#_cursor.targets = _selected_action.get_possible_targets()
	#add_child(_cursor)
	#
	## Finally, connect to the cursor's signals that will indicate that targets have been chosen.
	#_cursor.targets_selected.connect(
		#func _on_cursor_targets_selected(targets: Array[Battler]) -> void:
			## The cursor will be freed after emitting this signal. Remove reference to the cursor.
			#_cursor = null
			#
			#if not targets.is_empty():
				## At this point, the player should have selected a valid action and assigned it
				## targets, so the action may be cached for whenever the battler is ready.
				#CombatEvents.action_selected.emit(_selected_action, _selected_battler, targets)
				#
				## The player has properly queued an action. Return the UI to the state where the
				## player will pick a player Battler.
				#CombatEvents.player_battler_selected.emit(null)
			#
			#else:
				#_selected_action = null
				#_create_action_menu()
	#)
	
