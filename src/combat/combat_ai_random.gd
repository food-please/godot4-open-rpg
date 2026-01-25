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
## Battler's [member Battler.actions] and then randomly chooses a target.
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
func select_action(source: Battler) -> BattlerAction:
	print("%s looking for actions!" % source.name)
	
	var selected_action: BattlerAction = null
	
	# Keep track of how many times the controller has tried to find a valid action. In the event
	# that the controller fails ITERATION_MAX times, it will cease searching for an action.
	var iteration_counter = 0
	
	if not source.actions.is_empty():
		while iteration_counter < ITERATION_MAX and selected_action == null:
			# Randomly choose an action.
			var action_index: = randi() % source.actions.size()
			var action: BattlerAction = source.actions[action_index].duplicate()
			
			# Randomly choose a target.
			var possible_targets: = action.get_possible_targets()
			var targets: Array[Battler] = []
			if action.targets_all():
				targets = possible_targets
			else:
				var target_index: = randi() % possible_targets.size()
				targets.append(possible_targets[target_index])
			
			# If there are valid targets, register the action.
			if not targets.is_empty():
				_has_selected_action = true
				
				action.cached_targets = targets
				source.cached_action = action
				
				CombatEvents.action_selected.emit(action, source, targets)
			
			iteration_counter += 1
	
	return selected_action
