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
var _shoot_cd     := 0.0
var _unlocked     := false
var _bgm_player:   AudioStreamPlayer = null
var _bgm_stream:   AudioStreamWAV    = null

func _ready() -> void:
	_shoot_stream     = _build_magic_shoot_sfx()
	_enemy_die_stream = _build_hit_sfx()
	_evolve_stream    = _build_chime([523.25, 622.25, 739.99, 880.0, 1046.50], 0.1, true)
	_damage_stream    = _build_damage_sfx()
	_game_over_stream = _build_chime([440.0, 349.23, 261.63, 196.0], 0.22, false)
	_item_stream      = _build_chime([523.25, 659.25, 783.99], 0.09, false)
	_lap_streams = {
		"perfect": _build_chime([880.0, 1108.73, 1318.51], 0.08, true),
		"great":   _build_chime([659.25, 880.0],           0.1,  false),
		"good":    _build_chime([523.25],                  0.12, false),
		"miss":    _build_chime([349.23, 261.63],          0.15, false),
	}
	_bgm_stream = _build_bgm()
	for i in range(6):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.volume_db = -10.0
	add_child(_bgm_player)

func unlock() -> void:
	if _unlocked: return
	_unlocked = true
	# Web ブラウザの AudioContext を最初のタッチで解放する
	var p := _players[0]
	p.volume_db = -80.0
	p.stream = _shoot_stream
	p.play()
	await get_tree().process_frame
	p.volume_db = 0.0

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

func play_bgm() -> void:
	if _bgm_player.playing: return
	_bgm_player.stream = _bgm_stream
	_bgm_player.play()

func stop_bgm() -> void:
	_bgm_player.stop()

func _play(stream: AudioStreamWAV) -> void:
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = stream
	p.play()

func _build_magic_shoot_sfx() -> AudioStreamWAV:
	# 高音から急降下するピッチ＋倍音でキラッとした魔法弾の発射音にする
	var dur := 0.09
	var n   := int(MIX_RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t    := float(i) / MIX_RATE
		var env  := exp(-t * 30.0)
		var freq := 1500.0 - t * 3400.0
		var s : float = (sin(TAU * freq * t) * 0.7 + sin(TAU * freq * 2.01 * t) * 0.2) * env * 0.3
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

func _build_bgm() -> AudioStreamWAV:
	# SIGIL世界観（ダークファンタジー・壊れた紋章の世界）に合わせ、
	# 明るい8分ハイハットのアルペジオ主体から、低いドローン＋遠い鼓動＋
	# 疑似リバーブの効いたゆっくりしたアルペジオへ作り直した（2026-07-12）。
	# 2026-07-14：パッド（持続和音）ときらめきレイヤーを追加して厚みを増やした。
	# ついでにコード進行が2種類しか鳴っていなかったバグ（bar_idxの周期がズレていた）も修正。
	var bpm    := 72.0
	var beat_s := 60.0 / bpm
	var total_s := beat_s * 8.0        # 2小節ループ
	var n      := int(MIX_RATE * total_s)
	var data   := PackedByteArray()
	data.resize(n * 2)
	# Cマイナー: C3 Eb3 F3 Ab3（2拍ごとに切り替え）
	var bass_freqs: Array[float] = [130.81, 155.56, 174.61, 207.65]
	# リードアルペジオ: Cマイナー7th（1オクターブ下げて重心を低く）
	var lead_notes: Array[float] = [130.81, 155.56, 196.0, 233.08]
	# きらめき（オフビートに散らす高音のベル）
	var sparkle_beats: Array[float] = [1.75, 3.75, 5.75, 7.75]
	var echo_samples := int(MIX_RATE * beat_s * 0.5)
	for i in range(n):
		var t      := float(i) / float(MIX_RATE)
		var beat_t := t / beat_s              # 拍カウント（0〜8）
		var s      := 0.0
		# ── 低いドローン（常時鳴る不穏な持続音。ゆっくり揺れる）──
		var drone_f := 65.41 * (1.0 + 0.006 * sin(TAU * 0.15 * t))
		s += sin(TAU * drone_f * t) * 0.09
		s += sin(TAU * drone_f * 1.5 * t) * 0.035
		# ── 遠い鼓動のようなキック（1小節に1回）──
		var kick_t   := fmod(t, beat_s * 4.0)
		var kick_env := exp(-kick_t * 9.0)
		var kick_f   := 55.0 * (1.0 + 1.8 * exp(-kick_t * 22.0))
		s += sin(TAU * kick_f * kick_t) * kick_env * 0.5
		# ── ベースライン（2拍ごとにコード進行、4つとも鳴る）──
		var bar_idx   := int(beat_t / 2.0) % bass_freqs.size()
		var bass_freq := bass_freqs[bar_idx]
		var bass_t    := fmod(t, beat_s * 2.0)
		var bass_env  := maxf(0.0, 1.0 - bass_t / (beat_s * 2.0) * 1.15)
		s += sin(TAU * bass_freq * t) * bass_env * 0.24
		# ── パッド（持続和音。ルート+5度+オクターブを薄く重ねて厚みを出す）──
		var pad_env := 0.5 - 0.5 * cos(TAU * clampf(bass_t / (beat_s * 2.0), 0.0, 1.0))  # 滑らかにスウェル
		s += (sin(TAU * bass_freq * t) * 0.5 + sin(TAU * bass_freq * 1.5 * t) * 0.35 + sin(TAU * bass_freq * 2.0 * t) * 0.2) * pad_env * 0.06
		# ── リードアルペジオ（4分音符・減衰長め）──
		var lead_idx  := int(beat_t) % lead_notes.size()
		var lead_freq := lead_notes[lead_idx]
		var lead_t    := fmod(t, beat_s)
		var lead_env  := exp(-lead_t * 3.2)
		s += sin(TAU * lead_freq * t) * lead_env * 0.16
		# ── きらめき（高音のベルを控えめに散らす）──
		for sp in sparkle_beats:
			var sp_t := beat_t - sp
			if sp_t >= 0.0 and sp_t < 0.4:
				var sp_env := exp(-sp_t * 12.0)
				s += sin(TAU * 1046.5 * sp_t) * sp_env * 0.06
				break
		# ── 疑似リバーブ（0.5拍前の音を薄く重ねて残響にする）──
		if i >= echo_samples:
			var prev := float(data.decode_s16((i - echo_samples) * 2)) / 32767.0
			s += prev * 0.22
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	var stream := _wrap_wav(data)
	stream.loop_mode  = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end   = n - 1
	return stream

func _wrap_wav(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format    = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate  = MIX_RATE
	stream.stereo    = false
	stream.data      = data
	return stream
