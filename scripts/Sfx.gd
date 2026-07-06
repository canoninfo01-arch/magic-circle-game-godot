extends Node

const MIX_RATE := 22050

var _shoot_stream:     AudioStreamWAV
var _enemy_die_stream: AudioStreamWAV
var _evolve_stream:    AudioStreamWAV
var _damage_stream:    AudioStreamWAV
var _game_over_stream: AudioStreamWAV
var _item_stream:      AudioStreamWAV
var _lap_streams:      Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player  := 0
var _shoot_cd     := 0.0  # 連射音の間引き

func _ready() -> void:
	_shoot_stream     = _build_tone(1100.0, 0.04, 50.0, 0.25)
	_enemy_die_stream = _build_hit_sfx()
	_evolve_stream    = _build_chime([440.0, 554.37, 659.25, 880.0, 1108.73], 0.09, true)
	_damage_stream    = _build_damage_sfx()
	_game_over_stream = _build_chime([440.0, 349.23, 261.63, 196.0], 0.22, false)
	_item_stream      = _build_chime([523.25, 659.25, 783.99], 0.09, false)
	_lap_streams = {
		"perfect": _build_chime([880.0, 1108.73, 1318.51], 0.08, true),
		"great":   _build_chime([659.25, 880.0],           0.1,  false),
		"good":    _build_chime([523.25],                  0.12, false),
		"miss":    _build_chime([349.23, 261.63],          0.15, false),
	}
	for i in range(6):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

func _process(delta: float) -> void:
	if _shoot_cd > 0.0: _shoot_cd -= delta

func play_shoot() -> void:
	if _shoot_cd > 0.0: return
	_shoot_cd = 0.12
	_play(_shoot_stream)

func play_enemy_die() -> void: _play(_enemy_die_stream)
func play_evolve()    -> void: _play(_evolve_stream)
func play_damage()    -> void: _play(_damage_stream)
func play_game_over() -> void: _play(_game_over_stream)
func play_item()      -> void: _play(_item_stream)

func play_lap(grade: String) -> void:
	if _lap_streams.has(grade):
		_play(_lap_streams[grade] as AudioStreamWAV)

func play_card_get(rarity: int = 1) -> void:
	_play(_item_stream if rarity < 3 else _evolve_stream)

func _play(stream: AudioStreamWAV) -> void:
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = stream
	p.play()

func _build_tone(freq: float, dur: float, decay: float, vol: float) -> AudioStreamWAV:
	var n := int(MIX_RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t := float(i) / MIX_RATE
		var s : float = sin(TAU * freq * t) * exp(-t * decay) * vol
		data.encode_s16(i * 2, int(clamp(s, -1.0, 1.0) * 32767.0))
	return _wrap_wav(data)

func _build_damage_sfx() -> AudioStreamWAV:
	var dur := 0.15
	var n   := int(MIX_RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t   := float(i) / MIX_RATE
		var env := exp(-t * 18.0)
		var s : float = clamp((randf_range(-1.0, 1.0) * 0.5 + sin(TAU * 160.0 * t) * 0.5) * env, -1.0, 1.0)
		data.encode_s16(i * 2, int(s * 32767.0))
	return _wrap_wav(data)

func _build_hit_sfx() -> AudioStreamWAV:
	var dur := 0.12
	var n   := int(MIX_RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t      := float(i) / MIX_RATE
		var env    := exp(-t * 28.0)
		var noise  := randf_range(-1.0, 1.0)
		var thump  := sin(2.0 * PI * 90.0 * t)
		var s : float = clamp((noise * 0.6 + thump * 0.4) * env, -1.0, 1.0)
		data.encode_s16(i * 2, int(s * 32767.0))
	return _wrap_wav(data)

func _build_chime(notes: Array[float], note_dur: float, vibrato_last: bool) -> AudioStreamWAV:
	var n_per_note := int(MIX_RATE * note_dur)
	var data := PackedByteArray()
	data.resize(n_per_note * notes.size() * 2)
	var idx := 0
	for ni in range(notes.size()):
		var freq    := notes[ni]
		var is_last := vibrato_last and ni == notes.size() - 1
		for i in range(n_per_note):
			var t   := float(i) / MIX_RATE
			var env := exp(-t * 9.0)
			var f   := freq * (1.0 + 0.02 * sin(TAU * 22.0 * t)) if is_last else freq
			var s : float = clamp(sin(2.0 * PI * f * t) * env, -1.0, 1.0)
			data.encode_s16(idx * 2, int(s * 32767.0))
			idx += 1
	return _wrap_wav(data)

func _wrap_wav(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format    = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate  = MIX_RATE
	stream.stereo    = false
	stream.data      = data
	return stream
