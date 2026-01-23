# Participating Battlers must be descendents of this node.
@icon("icon_turn_queue.png")
#class_name CombatTurnQueue extends Node
class_name BattlerRoster extends Node

## Emitted whenever the combat logic has finished, including all animation details.
#signal finished(has_player_won: bool)

## A list of the combat participants, in [BattlerRoster] form. This object is created by the turn
## queue from children [Battler]s and then made available to other combat systems.
#var battler_roster: BattlerRoster
#
### Tracks which combat round is currently being played. Every round, all active Actors will get a
### turn to act.
#var round_count = 1:
	#set(value):
		#round_count = value
		#print("\nBegin turn %d" % round_count)
#
#
##func _ready() -> void:
	##battler_roster = BattlerRoster.new(self)
#
#
## Combat occurs in two phases: Battlers choose their actions and then act them out. The first phase
## sees all AI Battlers choose their action, followed by the player. Player actions are chosen by
## repeatedly calling _select_next_player_action.
#func next_round() -> void:
	#round_count += 1
	#
	## First of all, let enemy (necessarily AI) battlers pick their actions.
	#for battler in battler_roster.find_live_battlers(battler_roster.get_enemy_battlers()):
		#if battler.ai != null:
			#battler.ai.select_action(battler, battler_roster)
		#print("%s picked: " % battler.name, battler.cached_action)
	#
	## Secondly, allow player Battlers to pick their action.
	## This will be iterative as the player selects and cancels their choices. The turn queue will
	## move to the action phase once all player Battlers have an action selected.
	#_select_next_player_action()
#
#
## Player Battlers select their actions by repeatedly calling _select_next_player_action. The method
## looks for player Battlers who have no cached action and prioritizes those further up in the scene
## tree. This allows the player to go "backwards" and "forwards" between Battlers, choosing actions
## and cancelling them as needed.
## At this point, all AI Battlers should have a cached actoin.
## Once all Battlers have an action cached (see Battler.cached_action), _select_next_player_action
## calls _next_turn to move into the second phase.
#func _select_next_player_action() -> void:
	## Find any remaining player Battlers that need an action selected.
	#var player_battlers: = battler_roster.get_player_battlers()
	#var remaining_battlers: = battler_roster.find_battlers_needing_actions(player_battlers)
	#
	## If there are no player Battlers needing actions, move on to the second phase of a round:
	## taking action!
	#if remaining_battlers.is_empty():
		#print("No remaining actions, move to execution.")
		#_play_next_action.call_deferred()
		#return
	#
	## If there are player Battlers needing cached actions, pick the first one and allow it to search
	## for an action using either its AI controller (if present) or player input.
	#var next_player_battler: Battler = remaining_battlers.front()
	#print("%s looking for actions!" % next_player_battler.name)
	#next_player_battler.action_cached.connect(_select_next_player_action, 
		#CONNECT_DEFERRED | CONNECT_ONE_SHOT)
	#CombatEvents.player_battler_selected.emit(next_player_battler)
#
#
## The second phase of combat has each Battler act in order of speed. This is done by repeatedly
## calling _next_turn until no active Battlers have a cached action waiting to be executed.
#func _play_next_action() -> void:
	## Check for battle end conditions, that one side has been downed.
	#if battler_roster.are_battlers_defeated(battler_roster.get_player_battlers()):
		#finished.emit.call_deferred(false)
		#print("Player defeated")
		#return
	#elif battler_roster.are_battlers_defeated(battler_roster.get_enemy_battlers()):
		#finished.emit.call_deferred(true)
		#print("Enemies defeated")
		#return
#
	## Check for an active Battler. If neither side has lost yet there are no active actors, it's
	## time to start the next round.
	#var next_actor: = _get_next_actor()
	#if next_actor == null:
		#next_round()
		#return
	#
	## Connect to the actor's turn_finished signal. The actor is guaranteed to emit the signal,
	## even if it will be freed at the end of this frame.
	## However, we'll call_defer the next turn, since the current actor may have been downed on its
	## turn and we need a frame to process the change.
	#next_actor.turn_finished.connect(_play_next_action, CONNECT_DEFERRED | CONNECT_ONE_SHOT)
	#next_actor.act()
#
#
#func _get_next_actor() -> Battler:
	#var battlers: = battler_roster.get_battlers()
	#var ready_to_act_battlers: = battler_roster.find_ready_to_act_battlers(battlers)
	#if ready_to_act_battlers.is_empty():
		#return null
	#
	#ready_to_act_battlers.sort_custom(Battler.sort)
	#return ready_to_act_battlers.front()


## Returns all Battlers existing in the current combat.
func get_battlers() -> Array[Battler]:
	var battler_list: Array[Battler] = []
	battler_list.assign(find_children("*", "Battler"))
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
## [member Battler.is_active]) and have a cached action ready (see [member Battler.cached_action]).
func find_ready_to_act_battlers(battlers: Array[Battler]) -> Array[Battler]:
	return battlers.filter(
		func _filter_actors(actor: Battler) -> bool:
			return actor.is_active and actor.cached_action != null
	)


## Returns true if all the specified battlers are inactive.
func are_battlers_defeated(battlers: Array[Battler]) -> bool:
	for battler in battlers:
		if battler.is_active:
			return false
	
	return true


func _to_string() -> String:
	var battlers: = get_battlers()
	battlers.sort_custom(Battler.sort)

	#var msg: = "\n%s (CombatTurnQueue) - round %d" % [name, round_count]
	var msg: = "\n%s - BattlerRoster" % name
	for battler in battlers:
		msg += "\n\t" + battler.to_string()
	return msg
