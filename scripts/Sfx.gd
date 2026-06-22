extends Node

const MIX_RATE := 22050

var _hit_stream: AudioStreamWAV
var _card_get_stream: AudioStreamWAV
var _card_get_rare_stream: AudioStreamWAV
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0

func _ready() -> void:
	_hit_stream      = _build_hit_sfx()
	_card_get_stream = _build_chime([523.25, 659.25, 783.99], 0.1, false)
	_card_get_rare_stream = _build_chime([523.25, 659.25, 783.99, 1046.5], 0.12, true)
	for i in range(4):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

func play_hit() -> void:
	_play(_hit_stream)

func play_card_get(rarity: int = 1) -> void:
	_play(_card_get_rare_stream if rarity >= 3 else _card_get_stream)

func _play(stream: AudioStreamWAV) -> void:
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = stream
	p.play()

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
