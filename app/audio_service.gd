extends Node
## AudioService — Procedural 2-octave musical ring synthesizer & stage drone generator.
## Every ring release plays the next note in the current stage's 2-octave scale.
## Clean Solve triggers a full chord + musical flourish.

const SAMPLE_RATE := 22050.0

# 2-octave scales (14 notes each) per stage mood (Garden, Grove, Bridge, Temple, Peak, Summit)
const STAGE_SCALES := {
	1: [261.63, 293.66, 329.63, 392.00, 440.00, 523.25, 587.33, 659.25, 783.99, 880.00, 1046.50, 1174.66, 1318.51, 1567.98], # Garden: Bright Major Pentatonic
	2: [293.66, 329.63, 369.99, 440.00, 493.88, 587.33, 659.25, 739.99, 880.00, 987.77, 1174.66, 1318.51, 1479.98, 1760.00], # Grove: Warm Lydian Pentatonic
	3: [220.00, 246.94, 261.63, 329.63, 369.99, 440.00, 493.88, 523.25, 659.25, 739.99, 880.00, 987.77, 1046.50, 1318.51], # Bridge: Deep Dorian
	4: [261.63, 277.18, 349.23, 392.00, 415.30, 523.25, 554.37, 698.46, 783.99, 830.61, 1046.50, 1108.73, 1396.91, 1567.98], # Temple: Mystical Hirajoshi
	5: [196.00, 207.65, 246.94, 293.66, 311.13, 392.00, 415.30, 493.88, 587.33, 622.25, 783.99, 830.61, 987.77, 1174.66], # Peak: Tense Phrygian
	6: [174.61, 196.00, 207.65, 261.63, 277.18, 349.23, 392.00, 415.30, 523.25, 554.37, 698.46, 783.99, 830.61, 1046.50], # Summit: Dramatic Minor
}

var _sfx_player: AudioStreamPlayer
var _drone_player: AudioStreamPlayer
var _current_stage: int = 1
var _danger_zone_active: bool = false

func _ready() -> void:
	_sfx_player = AudioStreamPlayer.new()
	add_child(_sfx_player)
	_drone_player = AudioStreamPlayer.new()
	_drone_player.volume_db = -18.0
	add_child(_drone_player)

func set_stage_mood(stage: int, danger_zone: bool = false) -> void:
	_current_stage = clampi(stage, 1, 6)
	_danger_zone_active = danger_zone

func _is_sound_on() -> bool:
	return bool(SaveService.data["settings"].get("sound_enabled", true))

func _play_tone_sequence(freqs: Array, durations_ms: Array, wave_type: String = "sine", gain: float = 0.28) -> void:
	if not _is_sound_on():
		return
	var gen := AudioStreamWAV.new()
	gen.format = AudioStreamWAV.FORMAT_16_BITS
	gen.mix_rate = int(SAMPLE_RATE)
	gen.stereo = false

	var bytes := PackedByteArray()
	for i in range(freqs.size()):
		var freq: float = float(freqs[i])
		var dur_s: float = float(durations_ms[i]) / 1000.0
		var num_samples := int(SAMPLE_RATE * dur_s)
		for s in range(num_samples):
			var t := float(s) / SAMPLE_RATE
			var env := 1.0 - (float(s) / float(maxi(1, num_samples)))
			var sample := sin(TAU * freq * t)
			if wave_type == "triangle":
				sample = (2.0 / PI) * asin(sin(TAU * freq * t))
			elif wave_type == "chord":
				sample = 0.5 * sin(TAU * freq * t) + 0.3 * sin(TAU * freq * 1.25 * t) + 0.2 * sin(TAU * freq * 1.5 * t)
			var val := int(clampf(sample * env * gain, -1.0, 1.0) * 32767.0)
			bytes.append(val & 0xFF)
			bytes.append((val >> 8) & 0xFF)

	gen.data = bytes
	_sfx_player.stream = gen
	_sfx_player.play()

func play_piece_select() -> void:
	_play_tone_sequence([340.0], [45], "triangle", 0.22)

func play_rotation_tick(ring_radius_px: float = 80.0) -> void:
	var pitch := clampf(520.0 - ring_radius_px * 1.4, 220.0, 480.0)
	_play_tone_sequence([pitch], [22], "triangle", 0.14)

func play_near_alignment() -> void:
	_play_tone_sequence([880.0], [55], "sine", 0.18)

func play_blocked() -> void:
	_play_tone_sequence([145.0, 118.0], [55, 65], "triangle", 0.26)

func play_release(ring_order_index: int) -> void:
	var scale: Array = STAGE_SCALES.get(_current_stage, STAGE_SCALES[1])
	var note_idx := clampi(ring_order_index, 0, scale.size() - 1)
	var freq: float = float(scale[note_idx])
	_play_tone_sequence([freq], [160], "chord", 0.30)

func play_level_clear(is_clean_solve: bool) -> void:
	var scale: Array = STAGE_SCALES.get(_current_stage, STAGE_SCALES[1])
	if is_clean_solve:
		_play_tone_sequence([scale[0], scale[2], scale[4], scale[5]], [90, 90, 110, 260], "chord", 0.34)
	else:
		_play_tone_sequence([scale[0], scale[2], scale[4]], [95, 95, 190], "sine", 0.28)

func play_coin_chime(note_idx: int = 0) -> void:
	# Each coin that lands plays a step up, so a stack of coins is a rising run.
	var base := [987.77, 1108.73, 1318.51]
	var freq: float = float(base[clampi(note_idx, 0, base.size() - 1)])
	_play_tone_sequence([freq], [60, 110], "sine", 0.22)

func play_move_spent() -> void:
	_play_tone_sequence([240.0], [28], "triangle", 0.12)

func play_card_reveal(rarity: String) -> void:
	if rarity == "epic":
		_play_tone_sequence([523.25, 659.25, 783.99, 1046.50], [60, 60, 70, 200], "chord", 0.32)
	elif rarity == "rare":
		_play_tone_sequence([440.0, 554.37, 659.25], [65, 65, 160], "chord", 0.28)
	else:
		_play_tone_sequence([392.0, 523.25], [60, 120], "sine", 0.24)

func play_boss_intro() -> void:
	_play_tone_sequence([98.0, 110.0, 82.41], [140, 140, 320], "chord", 0.36)

func play_curse_applied() -> void:
	_play_tone_sequence([311.13, 277.18, 233.08], [80, 80, 160], "triangle", 0.26)

func play_danger_heartbeat() -> void:
	_play_tone_sequence([85.0, 72.0], [90, 130], "sine", 0.25)

func play_run_over() -> void:
	_play_tone_sequence([392.0, 349.23, 261.63], [140, 150, 320], "triangle", 0.28)

func play_revive() -> void:
	_play_tone_sequence([329.63, 440.0, 587.33, 783.99], [70, 70, 80, 200], "chord", 0.32)
