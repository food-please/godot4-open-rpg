# TODO: Improve description. Hint at VFX/SFX? 
## An arena is the background for a battle. It is a Control node that contains the battlers and the turn queue.
## It also contains the music that plays during the battle.
class_name CombatArena extends Control

## The music that will be automatically played during this combat instance.
@export var music: AudioStream

# Keep a reference to the turn queue, which handles combat logic including combat start and end.
@onready var turn_queue: = $Battlers as ActiveTurnQueue
