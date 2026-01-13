class_name BattlerRoster extends RefCounted

# Battlers searched for by the roster must be descendants (children, grandchildren, etc.) of this
# node. They will be found based on type - Battler.
var _battler_parent: Node


func _init(node: Node) -> void:
	_battler_parent = node


## Returns all Battlers existing in the current combat.
func get_battlers() -> Array[Battler]:
	var battler_list: Array[Battler] = []
	battler_list.assign(_battler_parent.find_children("*", "Battler"))
	return battler_list


## Returns all existing player Battlers.
func get_player_battlers() -> Array[Battler]:
	return get_battlers().filter(
		func _filter_players(battler: Battler):
			return battler.is_player
	)


## Returns all existing Battlers that are opposed to the player.
func get_enemy_battlers() -> Array[Battler]:
	return get_battlers().filter(
		func _filter_enemies(battler: Battler):
			return not battler.is_player
	)


## Filter an array of Battlers to return only whose health points are currently greater than 0.
func find_live_battlers(battlers: Array[Battler]) -> Array[Battler]:
	return battlers.filter(func(battler: Battler): return battler.stats.health > 0)


## Filter an array of Battlers to find those who are active but do not yet have a cached action (see
## [member Battler.cached_action]).
func find_battlers_needing_actions(battlers: Array[Battler]) -> Array[Battler]:
	return battlers.filter(
		func _filter_actors(actor: Battler) -> bool:
			return actor.is_active and actor.cached_action == null
	)


## Filter an array of Battlers to find those who may take an action. That is, they are active (see
## [member Battler.is_active]) and have not taken a turn yet this round (see
## [member Battler.has_acted_this_round]).
func find_ready_to_act_battlers(battlers: Array[Battler]) -> Array[Battler]:
	return battlers.filter(
		func _filter_actors(actor: Battler) -> bool:
			return actor.is_active and not actor.has_acted_this_round
	)


## Returns true if all the specified battlers are inactive.
func are_battlers_defeated(battlers: Array[Battler]) -> bool:
	for battler in battlers:
		if battler.is_active:
			return false
	
	return true
