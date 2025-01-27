## Displays the timeline representing the turn order of all battlers in the arena.
## Battler icons move along the timeline in real-time as their readiness updates.
class_name UITurnBar extends Control

const ICON_SCENE: = preload("ui_battler_icon.tscn")

@onready var _anim: = $AnimationPlayer as AnimationPlayer
@onready var _background: = $Background as TextureRect
@onready var _icons: = $Background/Icons as Control


## Fade in (from transparent) the turn bar and all of its UI elements.
func fade_in() -> void:
	_anim.play("fade_in")


## Fade out (to transparent) the turn bar and all of its UI elements.
func fade_out() -> void:
	_anim.play("fade_out")


## Initialize the turn bar, passing in all the battlers that we want to display.
func setup(battler_data: BattlerManager) -> void:
	for battler in battler_data.get_all_battlers():
		# Connect a handful of signals to the icon so that it may respond to changes in the
		# Battler's readiness and fade out if the Battler falls in combat.
		var icon: UIBattlerIcon = ICON_SCENE.instantiate()
		icon.icon = battler.anim.battler_icon
		icon.battler_type = (
			UIBattlerIcon.Types.PLAYER if battler.is_player else UIBattlerIcon.Types.ENEMY
		)
		icon.position_range = Vector2(
			-icon.size.x / 2.0,
			_background.size.x -icon.size.x / 2.0
		)

		battler.readiness_changed.connect(func(readiness: float): icon.progress = readiness / 100.0)
		battler.health_depleted.connect(icon.fade_out)
		
		_icons.add_child(icon)
