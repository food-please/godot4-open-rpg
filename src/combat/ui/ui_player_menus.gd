# Choosing an action occurs in two steps:
# 1) The player selects an action from a list.
# 2) The player then selects a target from a list of valid targets.
# The player may, at any time, opt to "go back" in the menu structure. This means that if the player
# was currently selecting a target, they would be returned to the action list. If the player was
# currently selecting an action, the menu structure would try to go back to the previous player
# Battler.
class_name UIPlayerMenus extends Control

signal selected(action: BattlerAction)

signal cancelled

## The action menu scene that will be created whenever the player needs to select an action.
@export var action_menu_scene: PackedScene

## The targetting cursor scene that will be created whenever the player needs to choose targets.
@export var target_cursor_scene: PackedScene


func choose_action(action_list: Array[BattlerAction]) -> void:
	pass


# On start:
# Create action menu
# If back, emit cancelled & free everything
# Otherwise, when selected, create target cursor. Only hide action menu.
# If back, free target cursor, unhide action menu
# If selected, cache targets and emit selected signal. Free everything.

func choose_targets() -> void:
	pass
