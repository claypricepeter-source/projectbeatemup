class_name Pickup
extends Area2D
## Ground item collected by pressing ATTACK over it (SoR2). Visuals bob above
## the logical ground position. Food heals (coffee = SoR2 apple, 32 of 104 HP;
## poutine = SoR2 chicken, full), cash adds score.

@export var kind: StringName = &"coffee"
@export var heal_amount := 0
@export var score_amount := 0

var collected := false
var _bob_time := 0.0

@onready var visuals: Node2D = $Visuals


func _process(delta: float) -> void:
	_bob_time += delta
	visuals.position.y = -6.0 + sin(_bob_time * 5.0) * 2.0


func collect(player: Player) -> void:
	if player == null or collected:
		return
	collected = true
	AudioManager.play_sfx(&"pickup", -6.0)
	if heal_amount > 0:
		player.hp = mini(player.hp + heal_amount, player.max_hp)
		EventBus.fighter_damaged.emit(player)
	if score_amount > 0:
		GameState.add_score(score_amount)
	EventBus.pickup_collected.emit(kind)
	set_deferred("monitoring", false)
	queue_free.call_deferred()
