extends Node
## AudioManager — musik, SFX, dan ambient dengan synthesizer prosedural.
##
## Seluruh suara dibangkitkan saat runtime (AudioStreamWAV) sehingga game
## langsung berbunyi tanpa file audio eksternal. Jika tersedia file di
## res://assets/audio/(music|sfx|ambient)/<id>.ogg/.wav, file itu dipakai.

const MIX_RATE := 16000

var music_volume: float = 0.8
var sfx_volume: float = 0.9
var ambient_volume: float = 0.7
var muted: bool = false

var _music_player: AudioStreamPlayer
var _music_player_b: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _sfx_players: Array = []
var _spatial_players: Array = []  # AudioStreamPlayer3D di dunia (volume = suasana)
var _sfx_index: int = 0
var _current_music: String = ""
var _current_ambient: String = ""
var _cache: Dictionary = {}  # id -> AudioStreamWAV
var _tween: Tween

# Progresi akor per trek musik (frekuensi dasar Hz, gaya pad melankolis).
const MUSIC_PRESETS := {
	"music_main_menu": [174.61, 146.83, 196.0, 164.81],      # F-G minor-ish
	"music_rumah_nenek": [130.81, 164.81, 146.83, 196.0],     # C-E-D-G
	"music_kafe": [196.0, 174.61, 220.0, 196.0],              # G-F-A-G ceria
	"music_pasar": [220.0, 196.0, 174.61, 196.0],
	"music_stasiun": [110.0, 130.81, 98.0, 146.83],           # rendah & suram
	"music_pantai": [146.83, 174.61, 130.81, 164.81],
	"music_makam": [123.47, 146.83, 110.0, 130.81],           # B-D-A-C: tenang, pasrah
	"music_investigation": [164.81, 164.81, 196.0, 146.83],
	"music_memory": [261.63, 220.0, 174.61, 196.0],           # kilas balik
	"music_ending": [130.81, 146.83, 164.81, 196.0],
}

const AMBIENT_PRESETS := ["ambient_rumah", "ambient_kafe", "ambient_pasar", "ambient_stasiun", "ambient_pantai", "ambient_city", "ambient_bukit"]


func _ready() -> void:
	_music_player = _make_player("Music")
	_music_player_b = _make_player("MusicB")
	_ambient_player = _make_player("Ambient")
	for i in 8:
		_sfx_players.append(_make_player("SFX%d" % i))
	var bus := SignalBus
	bus.music_requested.connect(play_music)
	bus.ambient_requested.connect(play_ambient)
	bus.sfx_requested.connect(play_sfx)
	_apply_volumes()


func _make_player(player_name: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = player_name
	p.bus = &"Master"
	add_child(p)
	return p


func _apply_volumes() -> void:
	var m: float = 0.0 if muted else music_volume
	var s: float = 0.0 if muted else sfx_volume
	var a: float = 0.0 if muted else ambient_volume
	_music_player.volume_db = linear_to_db(maxf(m * 0.5, 0.0001))
	_music_player_b.volume_db = linear_to_db(maxf(m * 0.5, 0.0001))
	_ambient_player.volume_db = linear_to_db(maxf(a * 0.35, 0.0001))
	for p in _sfx_players:
		(p as AudioStreamPlayer).volume_db = linear_to_db(maxf(s, 0.0001))
	for sp in _spatial_players:
		_apply_spatial_volume(sp as AudioStreamPlayer3D)


func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	_apply_volumes()


func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	_apply_volumes()


## Stream loop prosedural untuk sumber suara 3D di dunia (AudioStreamPlayer3D).
func spatial_stream(sound_id: String) -> AudioStreamWAV:
	if _cache.has("p:" + sound_id):
		return _cache["p:" + sound_id]
	var stream: AudioStreamWAV = _synth_spatial(sound_id)
	_cache["p:" + sound_id] = stream
	return stream


## Daftarkan pemutar 3D agar volumenya mengikuti slider suasana.
func register_spatial(p: AudioStreamPlayer3D, base_db: float = 0.0) -> void:
	p.set_meta("base_db", base_db)
	_spatial_players.append(p)
	p.tree_exited.connect(func() -> void: _spatial_players.erase(p))
	_apply_spatial_volume(p)


func _apply_spatial_volume(p: AudioStreamPlayer3D) -> void:
	if not is_instance_valid(p):
		return
	var a: float = 0.0 if muted else ambient_volume
	p.volume_db = linear_to_db(maxf(a, 0.0001)) + float(p.get_meta("base_db", 0.0))


func _synth_spatial(sound_id: String) -> AudioStreamWAV:
	var seconds: float = 4.0
	var n: int = int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = abs(hash(sound_id))
	var prev: float = 0.0
	var lp: float = 0.0
	var pop_t: float = 0.0
	for i in n:
		var t: float = float(i) / MIX_RATE
		var noise: float = rng.randf() * 2.0 - 1.0
		var v: float = 0.0
		match sound_id:
			"snd_fire":
				# Derak api: derau low-pass + letupan acak.
				lp = lp * 0.93 + noise * 0.07
				v = lp * 0.5 * (0.7 + 0.3 * sin(TAU * 0.6 * t))
				if rng.randf() < 0.0006:
					pop_t = t
				if t - pop_t < 0.03:
					v += (noise - prev) * 0.6 * (1.0 - (t - pop_t) / 0.03)
			"snd_radio":
				# Keroncong samar: melodi pentatonik lambat + statis.
				var notes: Array = [392.0, 440.0, 523.25, 587.33, 659.25, 587.33, 523.25, 440.0]
				var idx: int = int(t * 2.0) % notes.size()
				var f: float = float(notes[idx])
				var env: float = sin(fmod(t * 2.0, 1.0) * PI)
				v = (sin(TAU * f * t) * 0.5 + sin(TAU * f * 2.0 * t) * 0.15) * env * 0.25
				v += (noise - prev) * 0.12 + noise * 0.02
			"snd_lamp":
				# Lampu minyak: desis halus + kedip nada rendah.
				v = (noise - prev) * 0.05 + sin(TAU * 96.0 * t) * 0.02 * (0.5 + 0.5 * sin(TAU * 3.3 * t))
			"snd_bell":
				# Lonceng angin: 2–3 denting acak per loop, meluruh panjang.
				for b in [0.4, 1.9, 3.1]:
					var lb: float = t - float(b)
					if lb >= 0.0:
						v += (sin(TAU * 1318.5 * lb) * 0.5 + sin(TAU * 1975.5 * lb) * 0.25) * exp(-lb * 2.2) * 0.12
			"snd_sea":
				lp = lp * 0.985 + noise * 0.015
				v = lp * 6.0 * (0.55 + 0.45 * sin(TAU * 0.11 * t + 0.5))
			_:
				lp = lp * 0.98 + noise * 0.02
				v = lp * 2.0
		prev = noise
		samples[i] = clampf(v, -1.0, 1.0)
	_blend_loop_edge(samples, MIX_RATE / 4)
	return _make_wav(samples, true)


func set_ambient_volume(v: float) -> void:
	ambient_volume = clampf(v, 0.0, 1.0)
	_apply_volumes()


func set_muted(m: bool) -> void:
	muted = m
	_apply_volumes()


# ---------- Pemutaran ----------

## Putar musik dengan crossfade 1.2 detik.
func play_music(track_id: String) -> void:
	if track_id == "" or track_id == _current_music:
		return
	_current_music = track_id
	var stream: AudioStreamWAV = _get_music(track_id)
	var next_player: AudioStreamPlayer = _music_player_b if _music_player.playing else _music_player
	var prev_player: AudioStreamPlayer = _music_player if next_player == _music_player_b else _music_player_b
	next_player.stream = stream
	next_player.play()
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	var target_db: float = linear_to_db(maxf((0.0 if muted else music_volume) * 0.5, 0.0001))
	next_player.volume_db = -40.0
	_tween.tween_property(next_player, "volume_db", target_db, 1.2)
	if prev_player.playing:
		_tween.tween_property(prev_player, "volume_db", -40.0, 1.2)
		_tween.chain().tween_callback(prev_player.stop)


func stop_music() -> void:
	_current_music = ""
	_music_player.stop()
	_music_player_b.stop()


func play_ambient(track_id: String) -> void:
	if track_id == "" or track_id == _current_ambient:
		return
	_current_ambient = track_id
	_ambient_player.stream = _get_ambient(track_id)
	_ambient_player.play()


func stop_ambient() -> void:
	_current_ambient = ""
	_ambient_player.stop()


## Bangun stream lebih awal (dipanggil saat layar loading).
func precache_music(track_id: String) -> void:
	if track_id != "":
		_get_music(track_id)


func precache_ambient(track_id: String) -> void:
	if track_id != "":
		_get_ambient(track_id)


func play_sfx(sfx_id: String) -> void:
	if sfx_id == "":
		return
	var stream: AudioStreamWAV = _get_sfx(sfx_id)
	var p: AudioStreamPlayer = _sfx_players[_sfx_index] as AudioStreamPlayer
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()
	p.stream = stream
	p.pitch_scale = randf_range(0.97, 1.03)
	p.play()


# ---------- Penyediaan stream ----------

func _get_music(track_id: String) -> AudioStream:
	if _cache.has("m:" + track_id):
		return _cache["m:" + track_id]
	var stream: AudioStream = _try_load_file("music", track_id)
	if stream == null:
		var roots: Array = MUSIC_PRESETS.get(track_id, MUSIC_PRESETS["music_rumah_nenek"])
		stream = _synth_pad(roots, 8.0)
	_cache["m:" + track_id] = stream
	return stream


func _get_ambient(track_id: String) -> AudioStream:
	if _cache.has("a:" + track_id):
		return _cache["a:" + track_id]
	var stream: AudioStream = _try_load_file("ambient", track_id)
	if stream == null:
		stream = _synth_ambient(track_id)
	_cache["a:" + track_id] = stream
	return stream


func _get_sfx(sfx_id: String) -> AudioStream:
	if _cache.has("s:" + sfx_id):
		return _cache["s:" + sfx_id]
	var stream: AudioStream = _try_load_file("sfx", sfx_id)
	if stream == null:
		stream = _synth_sfx(sfx_id)
	_cache["s:" + sfx_id] = stream
	return stream


func _try_load_file(folder: String, stream_id: String) -> AudioStream:
	for ext in ["ogg", "wav", "mp3"]:
		var path: String = "res://assets/audio/%s/%s.%s" % [folder, stream_id, ext]
		if ResourceLoader.exists(path):
			var res: Resource = load(path)
			if res is AudioStream:
				return res
			if res is AudioStreamWAV:
				return res
	return null


# ---------- Synthesizer ----------

func _make_wav(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		var v: int = int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		if v < 0:
			v += 65536
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = samples.size()
	return wav


## Pad akorik: 4 akor mayor/minor bergantian, tiap nada = root+third+fifth+oktaf.
func _synth_pad(roots: Array, seconds: float) -> AudioStreamWAV:
	var n: int = int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var chord_len: float = seconds / 4.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	for i in n:
		var t: float = float(i) / MIX_RATE
		var chord_idx: int = mini(int(t / chord_len), 3)
		var root: float = float(roots[chord_idx])
		var third: float = root * 1.1892  # minor third
		if chord_idx % 2 == 1:
			third = root * 1.2599  # major third
		var fifth: float = root * 1.4983
		var pos_in_chord: float = fmod(t, chord_len) / chord_len
		var env: float = sin(pos_in_chord * PI)  # fade in-out per akor
		env = 0.25 + 0.75 * env
		var v: float = sin(TAU * root * t) * 0.30 \
			+ sin(TAU * third * t) * 0.18 \
			+ sin(TAU * fifth * t) * 0.15 \
			+ sin(TAU * root * 2.0 * t + 0.5) * 0.08 \
			+ sin(TAU * root * 0.5 * t) * 0.12
		v *= env * 0.5
		# Kilau lembut (shimmer) + noise vinyl sangat pelan.
		v += sin(TAU * root * 4.0 * t) * 0.015 * env
		v += (rng.randf() * 2.0 - 1.0) * 0.006
		samples[i] = v
	# Crossfade ujung agar loop mulus.
	_blend_loop_edge(samples, MIX_RATE / 2)
	return _make_wav(samples, true)


func _synth_ambient(track_id: String) -> AudioStreamWAV:
	var seconds: float = 8.0
	var n: int = int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = abs(hash(track_id))
	var wind_base: float = 0.05
	var chirp_rate: float = 0.0
	match track_id:
		"ambient_pantai":
			wind_base = 0.16  # ombak: noise termodulasi lambat
		"ambient_kafe", "ambient_pasar":
			wind_base = 0.08
			chirp_rate = 2.5  # celoteh samar
		"ambient_stasiun":
			wind_base = 0.06
		"ambient_bukit":
			wind_base = 0.11  # angin bukit lebih terbuka + jangkrik tipis
			chirp_rate = 0.9
		_:
			wind_base = 0.05
	var last: float = 0.0
	var rain: float = 0.045 if track_id == "ambient_stasiun" else 0.0
	var prev_noise: float = 0.0
	var horn_at: Array = [2.0, 5.5] if track_id == "ambient_stasiun" else []
	var gull_at: Array = [1.5, 4.0, 6.6] if track_id == "ambient_pantai" else []
	var bell_at: Array = [3.2, 7.1] if track_id == "ambient_bukit" else []
	for i in n:
		var t: float = float(i) / MIX_RATE
		var noise: float = rng.randf() * 2.0 - 1.0
		last = last * 0.985 + noise * 0.015  # low-pass (angin)
		var swell: float = 0.6 + 0.4 * sin(TAU * 0.12 * t + 1.0)
		var v: float = last * 8.0 * wind_base * swell
		if rain > 0.0:
			# Gerimis: noise high-pass (beda sampel) dengan gelombang intensitas lambat.
			v += (noise - prev_noise) * rain * (0.75 + 0.25 * sin(TAU * 0.09 * t))
			prev_noise = noise
		if chirp_rate > 0.0:
			# Kicau acak bernada tinggi & pendek.
			var gate: float = sin(TAU * chirp_rate * t) * sin(TAU * 0.37 * t + 2.0)
			if gate > 0.93:
				v += sin(TAU * (1800.0 + 400.0 * sin(TAU * 9.0 * t)) * t) * 0.02
		# Klakson kereta jauh (stasiun): akor disonan lembut.
		for h in horn_at:
			var lh: float = t - float(h)
			if lh >= 0.0 and lh < 1.6:
				var env_h: float = sin(minf(1.0, lh / 1.6) * PI)
				v += (sin(TAU * 311.0 * t) + sin(TAU * 370.0 * t) + sin(TAU * 466.0 * t)) * 0.03 * env_h
		# Tangis camar (pantai): sweep menurun pendek.
		for g in gull_at:
			var lg: float = t - float(g)
			if lg >= 0.0 and lg < 0.45:
				var ph: float = TAU * (1250.0 * lg - 0.5 * (550.0 / 0.45) * lg * lg)
				v += sin(ph) * 0.035 * sin(lg / 0.45 * PI)
		# Lonceng jauh (bukit): nada murni meluruh panjang.
		for b in bell_at:
			var lb: float = t - float(b)
			if lb >= 0.0 and lb < 2.4:
				v += (sin(TAU * 523.25 * t) * 0.6 + sin(TAU * 1046.5 * t) * 0.25) * 0.03 * exp(-lb * 1.6)
		samples[i] = v * 0.6
	_blend_loop_edge(samples, MIX_RATE / 2)
	return _make_wav(samples, true)


func _synth_sfx(sfx_id: String) -> AudioStreamWAV:
	match sfx_id:
		"sfx_dialogue_click", "sfx_typing":
			return _tone(880.0 if sfx_id == "sfx_typing" else 660.0, 0.06, 0.25, 8.0)
		"sfx_clue_found":
			return _chime([523.25, 659.25, 783.99], 0.5, 0.4)
		"sfx_deduction_correct":
			return _chime([392.0, 523.25, 659.25, 783.99], 0.7, 0.45)
		"sfx_deduction_wrong":
			return _chime([220.0, 174.61], 0.5, 0.4)
		"sfx_memory_exit":
			return _sweep(900.0, 180.0, 0.7, 0.25)
		"sfx_thunder":
			return _thump(46.0, 1.7, 0.5)
		"sfx_meow":
			return _meow()
		"sfx_purr":
			return _purr()
		"sfx_achievement":
			return _chime([523.25, 659.25, 783.99, 1046.5, 1318.5], 1.0, 0.4)
		"sfx_footstep_wood":
			return _thump(140.0, 0.09, 0.35)
		"sfx_footstep_wood_b":
			return _thump(128.0, 0.1, 0.33)
		"sfx_footstep_grass":
			return _thump(95.0, 0.11, 0.25)
		"sfx_footstep_grass_b":
			return _thump(88.0, 0.12, 0.23)
		"sfx_footstep_sand", "sfx_footstep_sand_b":
			return _crunch(0.12, 0.16, 0.6 if sfx_id.ends_with("_b") else 0.7)
		"sfx_footstep_gravel", "sfx_footstep_gravel_b":
			return _crunch(0.09, 0.3, 0.9 if sfx_id.ends_with("_b") else 1.0)
		"sfx_footstep_stone", "sfx_footstep_stone_b":
			return _thump(210.0 if sfx_id.ends_with("_b") else 240.0, 0.06, 0.3)
		"sfx_footstep_plank", "sfx_footstep_plank_b":
			return _plank(sfx_id.ends_with("_b"))
		"sfx_door_open":
			return _sweep(180.0, 420.0, 0.45, 0.3)
		"sfx_photo_taken":
			return _tone(1400.0, 0.08, 0.3, 12.0)
		"sfx_shutter":
			return _chime([1800.0, 900.0], 0.12, 0.35)
		"sfx_letter_open":
			return _noise_burst(0.25, 0.22)
		"sfx_memory":
			return _chime([1046.5, 783.99, 1046.5, 1318.5], 1.2, 0.3)
		"sfx_ambient_city":
			return _synth_ambient("ambient_city")
		"sfx_ui_hover":
			return _tone(520.0, 0.04, 0.12, 10.0)
		"sfx_ui_back":
			return _tone(330.0, 0.1, 0.25, 6.0)
		_:
			return _tone(440.0, 0.1, 0.25, 6.0)


func _tone(freq: float, seconds: float, amp: float, decay: float) -> AudioStreamWAV:
	var n: int = int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t: float = float(i) / MIX_RATE
		samples[i] = sin(TAU * freq * t) * amp * exp(-decay * t)
	return _make_wav(samples)


func _chime(freqs: Array, seconds: float, amp: float) -> AudioStreamWAV:
	var n: int = int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var step: float = seconds / float(freqs.size() + 1)
	for i in n:
		var t: float = float(i) / MIX_RATE
		var v: float = 0.0
		for k in freqs.size():
			var start: float = step * float(k)
			if t >= start:
				var lt: float = t - start
				v += sin(TAU * float(freqs[k]) * lt) * exp(-4.0 * lt)
		samples[i] = v * amp / float(freqs.size()) * 2.0
	return _make_wav(samples)


## Langkah di pasir/kerikil: derau ber-envelope; `grit` mengatur kekasaran high-pass.
func _crunch(seconds: float, amp: float, grit: float) -> AudioStreamWAV:
	var n: int = int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var prev: float = 0.0
	var lp: float = 0.0
	for i in n:
		var t: float = float(i) / MIX_RATE
		var noise: float = rng.randf() * 2.0 - 1.0
		var hp: float = noise - prev
		prev = noise
		lp = lp * 0.7 + noise * 0.3
		var env: float = exp(-22.0 * t) * (0.4 + 0.6 * minf(1.0, t / 0.01))
		samples[i] = (hp * grit + lp * (1.0 - grit)) * env * amp
	return _make_wav(samples)


## Papan dermaga: thump rendah + derit pendek yang naik nada.
func _plank(alt: bool) -> AudioStreamWAV:
	var n: int = int(MIX_RATE * 0.16)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var f0: float = 620.0 if alt else 540.0
	for i in n:
		var t: float = float(i) / MIX_RATE
		var v: float = sin(TAU * 110.0 * t) * exp(-28.0 * t) * 0.35
		if t > 0.03:
			var ts: float = t - 0.03
			v += sin(TAU * (f0 + 300.0 * ts) * ts) * exp(-18.0 * ts) * 0.12
		samples[i] = v
	return _make_wav(samples)


## Meong: sweep naik lalu turun dengan sedikit vibrato & harmonik.
func _meow() -> AudioStreamWAV:
	var seconds: float = 0.55
	var n: int = int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var phase: float = 0.0
	for i in n:
		var t: float = float(i) / MIX_RATE
		var u: float = t / seconds
		var f: float = 520.0 + 380.0 * sin(u * PI) + 18.0 * sin(TAU * 28.0 * t)
		phase += TAU * f / MIX_RATE
		var env: float = sin(u * PI) * (1.0 if u < 0.85 else (1.0 - u) / 0.15)
		var v: float = sin(phase) * 0.6 + sin(phase * 2.0) * 0.25 + sin(phase * 3.0) * 0.1
		samples[i] = v * env * 0.28
	return _make_wav(samples)


## Dengkuran: getaran rendah termodulasi ~25 Hz, 1.4 detik.
func _purr() -> AudioStreamWAV:
	var seconds: float = 1.4
	var n: int = int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var lp: float = 0.0
	for i in n:
		var t: float = float(i) / MIX_RATE
		lp = lp * 0.9 + (rng.randf() * 2.0 - 1.0) * 0.1
		var gate: float = 0.55 + 0.45 * sin(TAU * 25.0 * t)
		var breath: float = 0.6 + 0.4 * sin(TAU * 0.7 * t)
		var env: float = minf(1.0, t / 0.15) * minf(1.0, (seconds - t) / 0.3)
		samples[i] = (sin(TAU * 62.0 * t) * 0.5 + lp * 1.2) * gate * breath * env * 0.35
	return _make_wav(samples)


func _thump(freq: float, seconds: float, amp: float) -> AudioStreamWAV:
	var n: int = int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in n:
		var t: float = float(i) / MIX_RATE
		var f: float = freq * (1.0 - t * 2.0)
		var v: float = sin(TAU * maxf(f, 30.0) * t) * exp(-30.0 * t)
		v += (rng.randf() * 2.0 - 1.0) * 0.25 * exp(-60.0 * t)
		samples[i] = v * amp
	return _make_wav(samples)


func _sweep(f0: float, f1: float, seconds: float, amp: float) -> AudioStreamWAV:
	var n: int = int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var phase: float = 0.0
	for i in n:
		var t: float = float(i) / MIX_RATE
		var k: float = t / seconds
		var f: float = lerpf(f0, f1, k)
		phase += TAU * f / MIX_RATE
		samples[i] = sin(phase) * amp * sin(k * PI)
	return _make_wav(samples)


func _noise_burst(seconds: float, amp: float) -> AudioStreamWAV:
	var n: int = int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var last: float = 0.0
	for i in n:
		var k: float = float(i) / float(n)
		var noise: float = rng.randf() * 2.0 - 1.0
		last = last * 0.7 + noise * 0.3
		samples[i] = last * amp * sin(k * PI)
	return _make_wav(samples)


## Samarkan batas loop agar tidak terdengar "klik".
func _blend_loop_edge(samples: PackedFloat32Array, fade: int) -> void:
	var n: int = samples.size()
	fade = mini(fade, n / 4)
	for i in fade:
		var k: float = float(i) / float(fade)
		var a: float = samples[i]
		var b: float = samples[n - fade + i]
		var mixed: float = lerpf(b, a, k)
		samples[i] = mixed
		samples[n - fade + i] = mixed
