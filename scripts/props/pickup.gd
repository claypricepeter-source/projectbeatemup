class_name Pickup
extends Area2D
## Auto-collected ground pickup. Visuals bob above the logical ground position.

@export var kind: StringName = &"coffee"
@export var heal_amount := 0
@export var score_amount := 0

var collected := false
var _bob_time := 0.0

@onready var visuals: Node2D = $Visuals


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	_bob_time += delta
	visuals.position.y = -6.0 + sin(_bob_time * 5.0) * 2.0


func _on_area_entered(area: Area2D) -> void:
	var hurtbox := area as Hurtbox
	var player := hurtbox.fighter as Player if hurtbox else null
	if player == null or collected:
		return
	collected = true
	if heal_amount > 0:
		player.hp = mini(player.hp + heal_amount, player.max_hp)
		EventBus.fighter_damaged.emit(player)
	if score_amount > 0:
		GameState.add_score(score_amount)
	EventBus.pickup_collected.emit(kind)
	set_deferred("monitoring", false)
	queue_free.call_deferred()
