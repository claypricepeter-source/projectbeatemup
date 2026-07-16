class_name Biker
extends Enemy
## Charger enemy. Circle/charge states own movement; this hook records whether
## a charge connected so a miss can receive the longer punish window.

var charge_connected := false
var charge_missed := false
var charge_start_x := 0.0
var last_charge_distance := 0.0
var last_recovery_duration := 0.0


func on_attack_connected(_target: Fighter, _defeated: bool) -> void:
	if state_machine.current and state_machine.current.name == &"Charge":
		charge_connected = true
