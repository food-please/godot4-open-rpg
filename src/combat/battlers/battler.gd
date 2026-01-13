## A playable combatant that carries out [BattlerActions] as its [member readiness] charges.
##
## Battlers are the playable characters or enemies that show up in battle. They have [BattlerStats],
## a list of [BattlerAction]s to choose from, and respond to a variety of stimuli such as status
## effects and [BattlerHit]s, which typically deal damage or heal the Battler.
##
## [br][br]Battlers have [BattlerAnim]ation children which play out the Battler's actions.
@tool
class_name Battler extends Node2D

## Emitted whenever the Battler's turn is finished. Thos should emit only after all actions and 
## animations are complete.
signal turn_finished
## Forwarded from the receiving of [signal BettlerStats.health_depleted].
signal health_depleted
## Emitted when taking damage or being healed from a [BattlerHit].
## [br][br]Note the difference between this and [signal BattlerStats.health_changed]:
## 'hit_received' is always the direct result of an action, requiring graphical feedback.
signal hit_received(value: int)
## Emitted whenever a hit targeting this battler misses.
signal hit_missed
## Emitted when modifying `is_selected`. The user interface will react to this for
## player-controlled battlers.
signal selection_toggled(value: bool)

## The name of the node group that will contain all combat Battlers.
const GROUP: = "_COMBAT_BATTLER_GROUP"

## A Battler must have [BattlerStats] to act and receive actions.
@export var stats: BattlerStats = null
## Each action's data stored in this array represents an action the battler can perform.
## These can be anything: attacks, healing spells, etc.
@export var actions: Array[BattlerAction]

## Each Battler is shown on the screen by a [BattlerAnim] object. The object is created dynamically
## from a PackedScene, which must yield a [BattlerAnim] object when instantiated.
@export var battler_anim_scene: PackedScene:
	set(value):
		battler_anim_scene = value

		if not is_inside_tree():
			await ready

		# Free an already existing BattlerAnim.
		if anim:
			anim.queue_free()
			anim = null

		# Add the new BattlerAnim class as a child and link it to this Battler instance.
		if battler_anim_scene:
			# Normally we could wrap a check for battler_anim_scene's type (should be BattlerAnim)
			# in a call to assert, but we want the following code to run in the editor and clean up
			# dynamically if the user drops an incorrect PackedScene (i.e. not a BattlerAnim) into
			# the battler_anim_scene slot.
			var new_scene: = battler_anim_scene.instantiate()
			anim = new_scene as BattlerAnim
			if not anim:
				push_warning("Battler '%s' cannot accept '%s' as " % [name, new_scene.name],
					"battler_anim_scene. '%s' is not a BattlerAnim!" % new_scene.name)
				new_scene.free()
				battler_anim_scene = null
				return

			add_child(anim)
			var facing: = BattlerAnim.Direction.LEFT if is_player else BattlerAnim.Direction.RIGHT
			anim.setup(self, facing)

## A CombatAI object that will determine the Battler's combat behaviour.
## If the battler has an `ai_scene`, we will instantiate it and let the AI make decisions.
## If not, the player controls this battler. The system should allow for ally AIs.
@export var ai_scene: PackedScene:
	set(value):
		ai_scene = value

		if ai_scene != null:
			# In the editor, check to make sure that the value set to ai_scene is actually a
			# CombatAI bject.
			var new_instance: = ai_scene.instantiate()
			if Engine.is_editor_hint():
				if new_instance is not CombatAI:
					printerr("Cannot assign '%s' to Battler '%s'" % [new_instance.name, self.name] +
						" as ai_scene property. Assigned PackedScene is not a CombatAI type!")
					ai_scene = null
				new_instance.free()

			else:
				ai = new_instance
				add_child(ai)

## If this is [b]true[/b], this actor is controlled by the player. Use this to
## differentiate between player-controlled actors and AI-controlled ones.
## [/n][/n] Note that player Battlers may be controlled by an AI controller, but enemy Battlers may
## not be controlled by the player.
@export var is_player: = false:
	set(value):
		is_player = value
		if anim:
			var facing: = BattlerAnim.Direction.LEFT if is_player else BattlerAnim.Direction.RIGHT
			anim.direction = facing

## Reference to this Battler's child [CombatAI] node, if applicable.
var ai: CombatAI = null

## Reference to this Battler's child [BattlerAnim] node.
var anim: BattlerAnim = null

## If this is [b]true[/b], this Battler can take turns.
var is_active: bool = true:
	set(value):
		is_active = value

		set_process(is_active)

## If `true`, the battler is selected, which makes it move forward.
var is_selected: bool = false:
	set(value):
		if value:
			assert(is_selectable)

		is_selected = value
		selection_toggled.emit(is_selected)

## If `false`, the battler cannot be targeted by any action.
var is_selectable: bool = true:
	set(value):
		is_selectable = value
		if not is_selectable:
			is_selected = false

## Describes whether or not the Battler has taken a turn during this combat round.
var has_acted_this_round: = false


static func sort(a: Battler, b: Battler) -> bool:
	return a.stats.speed > b.stats.speed


func _ready() -> void:
	if not Engine.is_editor_hint():
		assert(stats, "Battler %s does not have stats assigned!" % name)

		add_to_group(GROUP)

		# Resources are NOT unique, so treat the currently assigned BattlerStats as a prototype.
		# That is, copy what it is now and use the copy, so that the original remains unaltered.
		stats = stats.duplicate()
		stats.initialize()
		stats.health_depleted.connect(func on_stats_health_depleted() -> void:
			is_active = false
			is_selectable = false
			health_depleted.emit()
		)


func start_turn() -> void:
	print(get_parent().name, " starts their turn!")

	await get_tree().create_timer(1.5).timeout
	turn_finished.emit()


func act(action: BattlerAction, targets: Array[Battler] = []) -> void:
	stats.energy -= action.energy_cost

	# action.execute() is almost certainly is a coroutine.
	@warning_ignore("redundant_await")
	await action.execute(self, targets)
	
	has_acted_this_round = true
	turn_finished.emit.call_deferred()


func take_hit(hit: BattlerHit) -> void:
	if hit.is_successful():
		hit_received.emit(hit.damage)
		stats.health -= hit.damage
	else:
		hit_missed.emit()


func _to_string() -> String:
	var msg: = "%s (CombatActor)" % name
	if not is_active:
		msg += " - INACTIVE"
	elif has_acted_this_round:
		msg += " - HAS ACTED"
	return msg
