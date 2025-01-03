## The cursor of a [UIActionMenuPage], indicating which option is currently in focus.
class_name UIMenuCursor extends Marker2D

## The time taken to move the cursor from one [UIActionButton] to the next.
const SLIDE_TIME: = 0.1

# The tween used to move the cursor between menu entries.
var _slide_tween: Tween = null


func _ready() -> void:
	# The arrow needs to move indepedently from its parent.
	set_as_top_level(true)


## Smoothly move the cursor to an arbitrary position.
## Called by the menu to move the cursor from entry to entry.
func move_to(target: Vector2) -> void:
	if _slide_tween:
		_slide_tween.kill()
	_slide_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_slide_tween.tween_property(self, "position", target, SLIDE_TIME)
