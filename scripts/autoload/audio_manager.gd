extends Node
## Run-wide music router. Two persistent players alternate so scene changes and
## boss entrances can crossfade without stage-local players restarting the track.

const STAGE_THEME: AudioStream = preload("res://assets/audio/music/stage_1_theme.mp3")
const CROSSFADE_SECONDS := 0.65
const SILENT_DB := -60.0
const SFX_POOL_SIZE := 8
const SFX_SAMPLE_RATE := 22050
const MUSIC_SAMPLE_RATE := 11025

# Compact original chiptune patterns. Stage 1 keeps the supplied full track;
# every other campaign state gets its own generated, loopable composition.
const MUSIC_PROFILES := {
	&"title": {"bpm": 96.0, "melody": [64, -1, 67, 71, 69, -1, 67, 64, 62, -1, 64, 67, 59, -1, 62, 64], "bass": [40, 40, 43, 43, 38, 38, 40, 40], "drums": 0.32, "volume_db": -18.0},
	&"stage_2": {"bpm": 108.0, "melody": [52, 55, 58, 55, 52, 60, 58, 55, 51, 55, 58, 63, 60, 58, 55, 51], "bass": [28, 28, 31, 31, 27, 27, 34, 31], "drums": 0.72, "volume_db": -16.0},
	&"stage_3": {"bpm": 138.0, "melody": [64, 67, 69, 71, 72, 71, 69, 67, 66, 69, 71, 74, 76, 74, 71, 69], "bass": [40, 40, 38, 38, 45, 43, 42, 38], "drums": 0.82, "volume_db": -15.0},
	&"boss": {"bpm": 152.0, "melody": [48, 49, 55, 54, 48, 58, 55, 49, 51, 52, 58, 57, 51, 60, 58, 52], "bass": [24, 24, 27, 25, 24, 29, 27, 25], "drums": 1.0, "volume_db": -13.0},
	&"clear": {"bpm": 126.0, "melody": [60, 64, 67, 72, 67, 72, 76, 79, 72, 76, 79, 84, 79, 76, 72, 67], "bass": [36, 36, 41, 41, 43, 43, 48, 48], "drums": 0.55, "volume_db": -17.0},
	&"game_over": {"bpm": 72.0, "melody": [60, -1, 58, -1, 55, -1, 51, -1, 48, -1, 46, -1, 43, -1, 39, -1], "bass": [36, 34, 31, 27, 24, 22, 19, 15], "drums": 0.12, "volume_db": -19.0},
	&"ending": {"bpm": 88.0, "melody": [64, -1, 67, -1, 71, 69, 67, -1, 62, -1, 66, -1, 69, 67, 64, -1], "bass": [40, 40, 43, 43, 38, 38, 40, 40], "drums": 0.18, "volume_db": -18.0},
}

const SFX_SPECS := {
	&"whiff": [0.12, 900.0, 260.0, 0.18],
	&"knockdown": [0.24, 125.0, 58.0, 0.48],
	&"breakable": [0.19, 310.0, 105.0, 0.7],
	&"pickup": [0.24, 520.0, 1120.0, 0.05],
	&"ui_confirm": [0.09, 760.0, 1040.0, 0.02],
	&"ui_pause": [0.13, 410.0, 620.0, 0.04],
	&"boss_stinger": [0.58, 145.0, 1180.0, 0.24],
}

var current_cue: StringName = &""
var _players: Array[AudioStreamPlayer] = []
var _music_cues: Dictionary = {}
var _active_index := -1
var _fade: Tween
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_streams: Dictionary = {}
var _sfx_cursor := 0
var last_sfx_cue: StringName = &""


func _ready() -> void:
	_music_cues[&"stage_1"] = {"stream": STAGE_THEME, "volume_db": -16.0, "pitch": 1.0, "generated": false}
	for cue: StringName in MUSIC_PROFILES:
		var profile: Dictionary = MUSIC_PROFILES[cue]
		_music_cues[cue] = {
			"stream": _build_music(profile, hash(cue)),
			"volume_db": float(profile["volume_db"]),
			"pitch": 1.0,
			"generated": true,
		}
	for index in 2:
		var player := AudioStreamPlayer.new()
		player.name = "Music%d" % (index + 1)
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		player.volume_db = SILENT_DB
		add_child(player)
		_players.append(player)
	for index in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "SFX%d" % (index + 1)
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_sfx_players.append(player)
	for cue: StringName in SFX_SPECS:
		_sfx_streams[cue] = _build_sfx(SFX_SPECS[cue], hash(cue))


func play_music(cue: StringName, restart := false) -> void:
	if not _music_cues.has(cue):
		push_warning("Unknown music cue: %s" % cue)
		return
	if current_cue == cue and not restart:
		return
	if _fade and _fade.is_valid():
		_fade.kill()

	var cue_data: Dictionary = _music_cues[cue]
	var next_index := 0 if _active_index != 0 else 1
	var next_player := _players[next_index]
	var previous: AudioStreamPlayer = _players[_active_index] if _active_index >= 0 else null
	var next_stream := cue_data["stream"] as AudioStream
	var start_position := 0.0
	if previous and previous.playing and previous.stream == next_stream and not restart:
		start_position = previous.get_playback_position()

	next_player.stop()
	next_player.stream = next_stream
	next_player.pitch_scale = float(cue_data["pitch"])
	next_player.volume_db = SILENT_DB
	next_player.play(start_position)
	_active_index = next_index
	current_cue = cue

	_fade = create_tween().set_parallel(true)
	_fade.tween_property(next_player, "volume_db", float(cue_data["volume_db"]), CROSSFADE_SECONDS)
	if previous:
		_fade.tween_property(previous, "volume_db", SILENT_DB, CROSSFADE_SECONDS)
		_fade.finished.connect(func() -> void:
			if is_instance_valid(previous) and previous != _players[_active_index]:
				previous.stop()
		)


func play_sfx(cue: StringName, volume_db := -5.0, pitch_scale := 1.0) -> void:
	var stream := _sfx_streams.get(cue) as AudioStream
	if stream == null:
		push_warning("Unknown SFX cue: %s" % cue)
		return
	var player: AudioStreamPlayer = null
	for candidate in _sfx_players:
		if not candidate.playing:
			player = candidate
			break
	if player == null:
		player = _sfx_players[_sfx_cursor]
		_sfx_cursor = (_sfx_cursor + 1) % _sfx_players.size()
	player.stop()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()
	last_sfx_cue = cue


func _build_sfx(spec: Array, rng_seed: int) -> AudioStreamWAV:
	var duration := float(spec[0])
	var start_hz := float(spec[1])
	var end_hz := float(spec[2])
	var noise_mix := float(spec[3])
	var sample_count := maxi(int(duration * SFX_SAMPLE_RATE), 1)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var random := RandomNumberGenerator.new()
	random.seed = rng_seed
	for index in sample_count:
		var time := float(index) / float(SFX_SAMPLE_RATE)
		var progress := float(index) / float(sample_count)
		var frequency_phase := TAU * (start_hz * time + 0.5 * (end_hz - start_hz) * time * progress)
		var tone := sin(frequency_phase) + sin(frequency_phase * 2.0) * 0.22
		var noise := random.randf_range(-1.0, 1.0)
		var attack := minf(progress / 0.025, 1.0)
		var envelope := attack * pow(1.0 - progress, 2.0)
		var sample := clampf((tone * (1.0 - noise_mix) + noise * noise_mix) * envelope * 0.72, -1.0, 1.0)
		bytes.encode_s16(index * 2, int(roundf(sample * 32767.0)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SFX_SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream


func _build_music(profile: Dictionary, rng_seed: int) -> AudioStreamWAV:
	var bpm := float(profile["bpm"])
	var melody: Array = profile["melody"]
	var bass: Array = profile["bass"]
	var drum_level := float(profile["drums"])
	var step_duration := 30.0 / bpm
	var duration := step_duration * float(melody.size())
	var sample_count := maxi(int(duration * MUSIC_SAMPLE_RATE), 1)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var random := RandomNumberGenerator.new()
	random.seed = rng_seed
	for index in sample_count:
		var time := float(index) / float(MUSIC_SAMPLE_RATE)
		var step := mini(int(time / step_duration), melody.size() - 1)
		var step_time := fmod(time, step_duration)
		var note_envelope := minf(step_time / 0.008, 1.0) * maxf(1.0 - step_time / step_duration * 0.38, 0.62)
		var melody_sample := 0.0
		var melody_note := int(melody[step])
		if melody_note >= 0:
			var melody_phase := fmod(time * _midi_frequency(melody_note), 1.0)
			melody_sample = (1.0 if melody_phase < 0.28 else -0.72) * note_envelope
		var bass_note := int(bass[step % bass.size()])
		var bass_phase := fmod(time * _midi_frequency(bass_note), 1.0)
		var bass_sample := (1.0 - 4.0 * absf(bass_phase - 0.5)) * 0.72
		var beat_time := fmod(time, step_duration * 2.0)
		var kick_envelope := exp(-beat_time * 20.0)
		var kick := sin(TAU * (76.0 - beat_time * 24.0) * beat_time) * kick_envelope
		var hat := random.randf_range(-1.0, 1.0) * exp(-step_time * 48.0) if step % 2 == 1 else 0.0
		var sample := clampf(melody_sample * 0.28 + bass_sample * 0.28 + (kick * 0.25 + hat * 0.08) * drum_level, -1.0, 1.0)
		bytes.encode_s16(index * 2, int(roundf(sample * 32767.0)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MUSIC_SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	stream.data = bytes
	return stream


func _midi_frequency(note: int) -> float:
	return 440.0 * pow(2.0, (float(note) - 69.0) / 12.0)


func get_debug_state() -> Dictionary:
	var active: AudioStreamPlayer = _players[_active_index] if _active_index >= 0 else null
	return {
		"cue": current_cue,
		"active_index": _active_index,
		"playing": active.playing if active else false,
		"pitch": active.pitch_scale if active else 0.0,
		"volume_db": active.volume_db if active else SILENT_DB,
		"position": active.get_playback_position() if active and active.playing else 0.0,
		"length": active.stream.get_length() if active and active.stream else 0.0,
		"generated": bool(_music_cues[current_cue]["generated"]) if _music_cues.has(current_cue) else false,
	}


func get_sfx_debug_state() -> Dictionary:
	var playing_count := 0
	for player in _sfx_players:
		if player.playing:
			playing_count += 1
	return {
		"cue_count": _sfx_streams.size(),
		"pool_size": _sfx_players.size(),
		"playing_count": playing_count,
		"last_cue": last_sfx_cue,
	}
