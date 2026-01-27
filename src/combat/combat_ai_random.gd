## The base class responsible for AI-controlled Battlers.
##
## For now, this simply selects a random [BattlerAction] and picks a random target, if one is
## available.
class_name CombatAI extends Node

## Defines the max number of loops that the controller will search for a valid action. If no valid
## action has been found after this number of iterations, the AI Battler will pass its turn.
const ITERATION_MAX: = 60

var _has_selected_action: = false

## Keep track of which Battler is controlled by this CombatAI.
#var source: Battler


## Connect to the signals of a given [Battler]. The callback randomly chooses an action from the
## Battler's [member Battler._actions] and then randomly chooses a target.
#func setup(battler: Battler, battler_roster: BattlerRoster) -> void:
	#source = battler
	#battler.ready_to_act.connect(
		#(func _on_battler_ready_to_act(source: Battler, battlers: BattlerRoster) -> void:
			#if not _has_selected_action:
				## Only a Battler with actions is able to act.
				#if source.actions.is_empty():
					#return
				#
				## Randomly choose an action.
				#var action_index: = randi() % source.actions.size()
				#var action: = source.actions[action_index]
				#
				## Randomly choose a target.
				#var possible_targets: = action.get_possible_targets(source, battlers)
				#var targets: Array[Battler] = []
				#if action.targets_all():
					#targets = possible_targets
				#else:
					#var target_index: = randi() % possible_targets.size()
					#targets.append(possible_targets[target_index])
				#
				## If there are targets, register the action.
				#if not targets.is_empty():
					#_has_selected_action = true
					#CombatEvents.action_selected.emit(action, source, targets)
				#else:
					#).bind(battler, battler_roster)
	#)
	#
	#battler.action_finished.connect(
		#func _on_battler_action_finished() -> void:
			#_has_selected_action = false
	#)


## This controller randomly chooses an action from the Battler's [member Battler.actions] and then
## randomly chooses a target.
func select_action(source: Battler) -> void:
	# Keep track of how many times the controller has tried to find a valid action. In the event
	# that the controller fails ITERATION_MAX times, it will cease searching for an action.
	# We do this because it is possible that the designer may create a scenario where there are
	# no valid actions to choose, in which case the AI would loop forever finding a valid action.
	var iteration_counter = 0
	
	if not source.actions.is_empty():
		while iteration_counter < ITERATION_MAX:
			# Randomly choose an action.
			var action_index: = randi() % source.actions.size()
			
			var selected_action: = source.actions[action_index]
			var action: BattlerAction = selected_action.duplicate()
			action.battler_roster = selected_action.battler_roster
			action.source = selected_action.source
			
			# Randomly choose a target.
			var possible_targets: = action.get_possible_targets()
			var targets: Array[Battler] = []
			if action.targets_all():
				targets = possible_targets
			else:
				var target_index: = randi() % possible_targets.size()
				targets.append(possible_targets[target_index])
			
			# If there are valid targets, register the action and exit the search loop.
			if not targets.is_empty():
				_has_selected_action = true
				
				action.cached_targets = targets
				source.cached_action = action
				return
			
			iteration_counter += 1
