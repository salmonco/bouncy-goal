class_name Sfx
extends Node3D

# 효과음을 코드로 합성해서 재생합니다. 소리 파일 없이 파형을 직접 만들어 AudioStreamWAV 로 씁니다.
# play_at 은 소리가 난 위치에서 재생해, 멀리서 난 소리는 작게 들립니다(듣는 위치는 현재 카메라).

const RATE := 22050
# 게임 세계는 캐릭터 키가 50 일 만큼 단위가 커서, 소리가 줄어드는 거리도 그만큼 키웁니다.
const UNIT_SIZE := 300.0
const MAX_DISTANCE := 4000.0
# 같은 소리도 매번 높낮이를 조금씩 바꿔 기계적으로 들리지 않게 합니다.
const PITCH_JITTER := 0.08

const KICK := &"kick"
const GROUND := &"ground"
const GOAL := &"goal"
const BLIZZARD := &"blizzard"

var _streams := {}
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
    _rng.seed = 1
    _streams = {KICK: _kick(), GROUND: _ground(), GOAL: _goal(), BLIZZARD: _blizzard()}
    _rng.randomize()

func play_at(sound: StringName, at: Vector3, volume_db := 0.0) -> void:
    var player := AudioStreamPlayer3D.new()
    player.stream = _streams[sound]
    player.position = at
    player.unit_size = UNIT_SIZE
    player.max_distance = MAX_DISTANCE
    player.volume_db = volume_db
    player.pitch_scale = 1.0 + _rng.randf_range(-PITCH_JITTER, PITCH_JITTER)
    add_child(player)
    player.finished.connect(player.queue_free)
    player.play()

# 위치와 상관없이 그대로 들리는 소리입니다. 골 차임처럼 화면 전체에 알리는 소리에 씁니다.
func play(sound: StringName, volume_db := 0.0) -> void:
    var player := AudioStreamPlayer.new()
    player.stream = _streams[sound]
    player.volume_db = volume_db
    add_child(player)
    player.finished.connect(player.queue_free)
    player.play()

# 눈뭉치를 차는 "퍽": 낮게 떨어지는 북소리에 눈이 부서지는 잡음을 섞습니다.
func _kick() -> AudioStreamWAV:
    var samples := PackedFloat32Array()
    var phase := 0.0
    var noise := 0.0
    for i in int(RATE * 0.16):
        var t := float(i) / RATE
        var frequency := 55.0 + 95.0 * exp(-t * 30.0)
        phase += TAU * frequency / RATE
        noise = lerpf(noise, _rng.randf_range(-1, 1), 0.25)
        samples.append(sin(phase) * exp(-t * 26.0) * 0.8 + noise * exp(-t * 45.0) * 0.9)
    return _wav(samples)

# 눈밭에 떨어지는 "푹": 부드럽게 뭉갠 잡음입니다.
func _ground() -> AudioStreamWAV:
    var samples := PackedFloat32Array()
    var noise := 0.0
    for i in int(RATE * 0.2):
        var t := float(i) / RATE
        noise = lerpf(noise, _rng.randf_range(-1, 1), 0.08)
        var attack := minf(t / 0.006, 1.0)
        samples.append(noise * attack * exp(-t * 22.0) * 1.6)
    return _wav(samples)

# 골 차임: 도-미-솔-도를 차례로 울립니다.
func _goal() -> AudioStreamWAV:
    var notes := [523.25, 659.25, 783.99, 1046.5]
    var samples := PackedFloat32Array()
    for i in int(RATE * 1.6):
        var t := float(i) / RATE
        var value := 0.0
        for n in notes.size():
            var start := n * 0.11
            if t >= start:
                var local := t - start
                value += (sin(TAU * notes[n] * local) + 0.3 * sin(TAU * notes[n] * 2.0 * local)) * exp(-local * 3.5) * 0.22
        samples.append(value)
    return _wav(samples)

# 눈보라 "휘이잉": 바람 같은 잡음이 차오르다 가라앉으며, 걸러내는 정도를 바꿔 휘몰아치는 느낌을 냅니다.
func _blizzard() -> AudioStreamWAV:
    var samples := PackedFloat32Array()
    var noise := 0.0
    var duration := 2.0
    for i in int(RATE * duration):
        var t := float(i) / RATE
        # 바람이 휘도는 것처럼 밝기(걸러내는 정도)가 오르내립니다.
        var brightness := 0.05 + 0.12 * (0.5 + 0.5 * sin(TAU * 2.5 * t)) * exp(-t * 0.8)
        noise = lerpf(noise, _rng.randf_range(-1, 1), brightness)
        var swell := minf(t / 0.25, 1.0) * exp(-maxf(t - 0.25, 0.0) * 1.8)
        samples.append(noise * swell * 2.2)
    return _wav(samples)

func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
    var data := PackedByteArray()
    data.resize(samples.size() * 2)
    for i in samples.size():
        data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = RATE
    stream.stereo = false
    stream.data = data
    return stream
