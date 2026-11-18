extends Node

const RATE := 22050
const BEAT := 0.48
var voices: Array[AudioStreamPlayer] = []
var clips := {}
var needle := 0
var music: AudioStreamPlayer
var score: AudioStreamWAV
var mix := 0.0
var muted := false
var stage_pitch := 1.0
var live := false
var menu_active := false
var noise := RandomNumberGenerator.new()

func _ready() -> void:
	noise.seed = 6831
	for i in 12:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	var table := {
		"jump": [240.0, 470.0, 0.125, 0.11, 0.20],
		"dodge": [330.0, 110.0, 0.15, 0.46, 0.15],
		"slash": [600.0, 170.0, 0.095, 0.54, 0.14],
		"hit": [138.0, 44.0, 0.18, 0.30, 0.54],
		"hurt": [300.0, 49.0, 0.27, 0.31, 0.53],
		"open": [500.0, 755.0, 0.30, 0.02, 0.25],
		"warn": [250.0, 220.0, 0.35, 0.09, 0.29],
		"slam": [85.0, 31.0, 0.26, 0.35, 0.54],
		"deny": [158.0, 134.0, 0.12, 0.05, 0.20],
		"steal": [188.0, 990.0, 0.49, 0.06, 0.41],
		"parry": [115.0, 780.0, 0.34, 0.15, 0.45],
		"rule": [350.0, 184.0, 0.23, 0.09, 0.30],
		"win": [220.0, 665.0, 0.64, 0.04, 0.34],
		"start": [110.0, 220.0, 0.37, 0.13, 0.37],
		"ui_focus": [410.0, 330.0, 0.043, 0.013, 0.052],
		"ui_confirm": [329.6, 493.8, 0.15, 0.026, 0.17],
		"objective": [329.6, 493.8, 0.30, 0.018, 0.21],
		"pickup": [523.3, 784.0, 0.26, 0.022, 0.24],
		"penalty": [286.0, 133.0, 0.25, 0.07, 0.20]
	}
	for key in table:
		var p: Array = table[key]
		clips[key] = _effect(p[0], p[1], p[2], p[3], p[4], key)
	music = AudioStreamPlayer.new()
	add_child(music)
	set_process(false)

func _effect(lo: float, hi: float, duration: float, grit: float, amp: float, key: String) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(int(RATE * duration) * 2)
	var angle := 0.0
	for i in range(data.size() / 2):
		var t := float(i) / float(RATE)
		var u := t / duration
		angle += TAU * lerpf(lo, hi, pow(u, 0.55)) / RATE
		var beep := sin(angle) * 0.67 + sin(angle * 2.01) * 0.18 + sin(angle * 3.0) * 0.10
		if key in ["steal", "win", "open"]:
			beep = beep * 0.6 + sin(angle * 1.498) * 0.28 + sin(angle * 2.0) * 0.12
		elif key in ["ui_confirm", "objective", "pickup", "penalty"]:
			beep = sin(angle) * 0.61 + sin(angle * 1.50) * 0.17 + sin(angle * 2.00) * 0.10
			beep += sin(angle * 3.015) * 0.12 * exp(-u * 8.0)
		var env := minf(u * 45.0, 1.0) * pow(1.0 - u, 2.0)
		data.encode_s16(i * 2, int((beep + noise.randf_range(-grit, grit)) * amp * env * 32700.0))
	return _wav(data)

func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var sample := AudioStreamWAV.new()
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.mix_rate = RATE
	sample.data = data
	return sample

func _compose() -> AudioStreamWAV:
	# Four-bar industrial loop: half-time kick, offbeat relay clicks and a sequenced bass.
	var data := PackedByteArray()
	var measures := 8
	var steps := 8 * measures
	data.resize(int(RATE * BEAT * 0.5 * steps) * 4)
	var notes := [46.25, 46.25, 69.30, 46.25, 55.0, 46.25, 41.20, 41.20]
	var bed := [138.59, 164.81, 110.0, 123.47, 146.83, 110.0, 130.81, 123.47]
	for i in range(data.size() / 4):
		var t := float(i) / float(RATE)
		var step := mini(steps - 1, int(t / (BEAT * 0.5)))
		var x := fposmod(t, BEAT * 0.5)
		var bar := step / 8
		var freq: float = notes[step % notes.size()] * (1.0 if bar % 2 == 0 else 0.89)
		var gate := minf(x * 105.0, 1.0) * exp(-x * 11.0)
		var value := (sin(TAU * freq * x) + sin(TAU * freq * 2.0 * x) * 0.21) * gate * 0.15
		if step % 8 in [0, 3, 6]:
			value += sin(TAU * (53.0 * x + 2.7 * (1.0 - exp(-x * 45.0)))) * exp(-x * 25.0) * minf(x * 600.0, 1.0) * 0.34
		var hiss := noise.randf_range(-1.0, 1.0)
		if step % 8 == 4:
			value += (hiss * 0.64 + sin(TAU * 173.0 * x) * 0.36) * exp(-x * 28.0) * minf(x * 500.0, 1.0) * 0.21
		elif step % 2 == 1:
			value += hiss * exp(-x * 91.0) * minf(x * 500.0, 1.0) * 0.12
		var pad_t := fposmod(t, BEAT * 4.0)
		var tone: float = bed[bar]
		var envelope := pow(sin(PI * pad_t / (BEAT * 4.0)), 2.0)
		var pad := sin(TAU * tone * pad_t) * envelope * 0.056
		var upper := sin(TAU * tone * 1.499 * pad_t) * envelope * 0.038
		var strike_t := fposmod(t, BEAT * 2.0)
		var glass := (sin(TAU * tone * 3.0 * strike_t) + sin(TAU * tone * 6.02 * strike_t) * 0.27) * exp(-strike_t * 5.0) * minf(strike_t * 60.0, 1.0) * 0.032
		data.encode_s16(i * 4, int(clampf(value + pad + upper * 0.48 + glass, -1.0, 1.0) * 32700.0))
		data.encode_s16(i * 4 + 2, int(clampf(value + pad * 0.84 + upper + glass * 0.59, -1.0, 1.0) * 32700.0))
	var sample := _wav(data)
	sample.stereo = true
	sample.loop_mode = AudioStreamWAV.LOOP_FORWARD
	sample.loop_end = data.size() / 4
	return sample

func set_mute(value: bool) -> void:
	muted = value
	for voice in voices:
		if muted:
			voice.stop()
	if music != null:
		music.volume_db = -80.0 if muted else linear_to_db(maxf(mix, 0.001))

func set_stage(stage: int, in_combat: bool) -> void:
	live = in_combat
	stage_pitch = 0.88 if stage < 0 else [0.97, 1.03, 1.0, 0.94, 0.91, 0.90, 1.05, 0.86][stage % 8]
	if music.playing or muted or (stage < 0 and not menu_active):
		return
	if score == null:
		score = _compose()
	music.stream = score
	music.volume_db = -50.0
	music.play()
	set_process(true)

func _process(delta: float) -> void:
	mix = move_toward(mix, 0.34 if live else 0.09, delta * 0.24)
	music.volume_db = -80.0 if muted else linear_to_db(maxf(mix, 0.001))
	music.pitch_scale = move_toward(music.pitch_scale, stage_pitch, delta * 0.3)

func fire(key: String) -> void:
	if key == "ui_confirm":
		menu_active = true
	if muted or not clips.has(key):
		return
	var voice := voices[needle]
	needle = (needle + 1) % voices.size()
	voice.stream = clips[key]
	voice.pitch_scale = noise.randf_range(0.97, 1.03)
	voice.play()
