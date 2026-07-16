extends AnimatedSprite2D

const CLAY_FRAMES: SpriteFrames = preload("res://assets/sprites/player/clay_character_godot/clay_character/godot/clay_sprite_frames.tres")

func _ready() -> void:
    sprite_frames = CLAY_FRAMES
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    centered = true
    if animation == &"":
        animation = &"idle"
    play()

func play_action(action_name: StringName, restart: bool = true) -> void:
    if not sprite_frames.has_animation(action_name):
        push_warning("Unknown Clay animation: %s" % action_name)
        return
    if restart:
        play(action_name)
    else:
        animation = action_name
        play()
