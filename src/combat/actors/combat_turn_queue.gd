@icon("icon_turn_queue.png")
class_name CombatTurnQueue extends Node

## Emitted whenever the combat logic has finished, including all animation details.
signal finished(has_player_won: bool)

## A list of the combat participants, in [BattlerRoster] form. This object is created by the turn
## queue from children [Battler]s and then made available to other combat systems.
var battler_roster: BattlerRoster

## Tracks which combat round is currently being played. Every round, all active Actors will get a
## turn to act.
var round_count = 1:
	set(value):
		round_count = value
		print("\nBegin turn %d" % round_count)


func _ready() -> void:
	battler_roster = BattlerRoster.new(self)


func start() -> void:
	round_count = 1
	_next_turn.call_deferred()


func _next_turn() -> void:
	# Check for battle end conditions, that one side has been downed.
	if battler_roster.are_battlers_defeated(battler_roster.get_player_battlers()):
		finished.emit.call_deferred(false)
		print("Player defeated")
		return
	elif battler_roster.are_battlers_defeated(battler_roster.get_enemy_battlers()):
		finished.emit.call_deferred(true)
		print("Enemies defeated")
		return

		# Check for an active actor. If there are none, it may be that the turn has finished and all
		# actors can have their has_acted_this_round flag reset.
	var next_actor: = _get_next_actor()
	if not next_actor:
		_reset_has_acted_flag()

		# If there is no actor now, there is a situation where the only remaining Battler's don't
		# have assigned actors. In other words, all controlled actors (player included) are downed.
		# In this case, register as a player loss.
		next_actor = _get_next_actor()
		if not next_actor:
			finished.emit(false)
			return

		round_count += 1
	
	next_actor.has_acted_this_round = true
	
	# Connect to the actor's turn_finished signal. The actor is guaranteed to emit the signal,
	# even if it will be freed at the end of this frame.
	# However, we'll call_defer the next turn, since the current actor may have been downed on its
	# turn and we need a frame to process the change.
	next_actor.turn_finished.connect(_next_turn, CONNECT_DEFERRED | CONNECT_ONE_SHOT)
	next_actor.start_turn()


func _get_next_actor() -> Battler:
	var battlers: = battler_roster.get_battlers()
	var ready_to_act_battlers: = battler_roster.find_ready_to_act_battlers(battlers)
	if ready_to_act_battlers.is_empty():
		return null
	
	ready_to_act_battlers.sort_custom(Battler.sort)
	return ready_to_act_battlers.front()


func _reset_has_acted_flag() -> void:
	for battler in battler_roster.get_battlers():
		battler.has_acted_this_round = false


func _to_string() -> String:
	var battlers: = battler_roster.get_battlers()
	battlers.sort_custom(Battler.sort)

	var msg: = "\n%s (CombatTurnQueue) - round %d" % [name, round_count]
	for battler in battlers:
		msg += "\n\t" + battler.to_string()
	return msg
