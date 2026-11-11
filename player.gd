extends CharacterBody2D
# Jogador: movimento, combo, habilidades, esquiva e dano recebido.

const GRAVITY := 1600.0
const JUMP_V := 720.0
const SIZE := Vector2(36, 64)

var main
var cls: Dictionary = {}
var level := 1
var st: Dictionary = {}
var hp := 1.0
var max_hp := 1.0
var energy := 1.0
var facing := 1
var combo_idx := 0
var combo_timer := 0.0
var lock := 0.0
var buffer_atk := 0.0
var buffer_jump := 0.0
var coyote := 0.0
var invuln := 0.0
var dodge_cd := 0.0
var shield_t := 0.0
var dash_t := 0.0
var dash_v := 0.0
var dash_hit: Dictionary = {}
var dash_list: Array = []
var cds: Array = [0.0, 0.0, 0.0]
var pending: Array = []
var dead := false
var body: ColorRect
var weapon: ColorRect
var aura: ColorRect
var cam: Camera2D
var light: PointLight2D
# Arte das classes (opcional: se os PNG existirem, substitui o retângulo)
const ART_K := 1.5   # pixel art: cada pixel do sprite = 1,5 px de tela (personagem 25% menor)
const CAST = {
	"warrior": {"wings": false, "weapon": "warrior_sword", "wpos": Vector2(22.5, -41.0), "pivot": Vector2(3, 5), "wscale": 1.5, "idle": 75.0, "a0": -80.0, "a1": 70.0},
	"archer": {"wings": false, "weapon": "archer_bow", "wpos": Vector2(22.5, -42.5), "pivot": Vector2(11, 24), "wscale": 1.5, "idle": 6.0, "a0": -22.0, "a1": 12.0},
	"mage": {"wings": false, "weapon": "mage_staff", "wpos": Vector2(21.75, -38.75), "pivot": Vector2(6, 38), "wscale": 1.5, "idle": 8.0, "a0": -50.0, "a1": 40.0}
}
# Animação quadro a quadro (folhas de 128x112 px por quadro, escala 2)
const ANIM_CLASSES := ["warrior", "mage", "archer"]
const ANIMS_WARRIOR := {
	"idle": {"n": 24},
	"run": {"n": 24},
	"jump": {"n": 2},
	"atk1": {"n": 21, "w": [0.2, 0.188, 0.176, 0.164, 0.152, 0.14, 0.144, 0.148, 0.152, 0.156, 0.16, 0.164, 0.168, 0.172, 0.176, 0.18, 0.18, 0.18, 0.18, 0.18, 0.18]},
	"atk2": {"n": 21, "w": [0.2, 0.192, 0.184, 0.176, 0.168, 0.16, 0.16, 0.16, 0.16, 0.16, 0.16, 0.164, 0.168, 0.172, 0.176, 0.18, 0.18, 0.18, 0.18, 0.18, 0.18]},
	"atk3": {"n": 26, "w": [0.2, 0.192, 0.184, 0.176, 0.168, 0.16, 0.152, 0.144, 0.136, 0.128, 0.12, 0.128, 0.136, 0.144, 0.152, 0.16, 0.18, 0.2, 0.22, 0.24, 0.26, 0.268, 0.276, 0.284, 0.292, 0.3]},
	"skill1": {"n": 26, "w": [0.16, 0.156, 0.152, 0.148, 0.144, 0.14, 0.152, 0.164, 0.176, 0.188, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.196, 0.192, 0.188, 0.184, 0.18]},
	"skill2": {"n": 16, "w": [0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2]},
	"skill3": {"n": 11, "w": [0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2]},
	"dodge": {"n": 11, "w": [0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2]},
	"hurt": {"n": 6, "w": [0.2, 0.2, 0.2, 0.2, 0.2, 0.2]}
}
const ANIMS_MAGE := {
	"idle": {"n": 48},
	"run": {"n": 32},
	"jump": {"n": 16},
	"atk1": {"n": 36, "w": [0.1857, 0.1755, 0.1653, 0.1551, 0.1449, 0.1347, 0.1245, 0.1143, 0.1122, 0.1102, 0.1082, 0.1061, 0.1041, 0.102, 0.1, 0.102, 0.1041, 0.1061, 0.1082, 0.1102, 0.1122, 0.1143, 0.1163, 0.1184, 0.1204, 0.1224, 0.1245, 0.1265, 0.1286, 0.1306, 0.1327, 0.1347, 0.1367, 0.1388, 0.1408, 0.1429]},
	"atk2": {"n": 36, "w": [0.1857, 0.1755, 0.1653, 0.1551, 0.1449, 0.1347, 0.1245, 0.1143, 0.1122, 0.1102, 0.1082, 0.1061, 0.1041, 0.102, 0.1, 0.102, 0.1041, 0.1061, 0.1082, 0.1102, 0.1122, 0.1143, 0.1163, 0.1184, 0.1204, 0.1224, 0.1245, 0.1265, 0.1286, 0.1306, 0.1327, 0.1347, 0.1367, 0.1388, 0.1408, 0.1429]},
	"atk3": {"n": 43, "w": [0.1429, 0.1408, 0.1388, 0.1367, 0.1347, 0.1327, 0.1306, 0.1286, 0.1265, 0.1245, 0.1224, 0.1204, 0.1184, 0.1163, 0.1143, 0.1143, 0.1143, 0.1143, 0.1143, 0.1143, 0.1143, 0.1143, 0.1163, 0.1184, 0.1204, 0.1224, 0.1245, 0.1265, 0.1286, 0.1306, 0.1327, 0.1347, 0.1367, 0.1388, 0.1408, 0.1429, 0.1429, 0.1429, 0.1429, 0.1429, 0.1429, 0.1429, 0.1429]},
	"skill1": {"n": 37, "w": [0.15, 0.1472, 0.1444, 0.1417, 0.1389, 0.1361, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1361, 0.1389, 0.1417, 0.1444, 0.1472, 0.15, 0.1444, 0.1389, 0.1333, 0.1278, 0.1222, 0.1167, 0.1194, 0.1222, 0.125, 0.1278, 0.1306, 0.1333, 0.1389, 0.1444, 0.15, 0.1556, 0.1611, 0.1667]},
	"skill2": {"n": 43, "w": [0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1361, 0.1389, 0.1417, 0.1444, 0.1472, 0.15, 0.1639, 0.1778, 0.1917, 0.2056, 0.2194, 0.2333, 0.2222, 0.2111, 0.2, 0.1889, 0.1778, 0.1667, 0.1639, 0.1611, 0.1583, 0.1556, 0.1528, 0.15, 0.1528, 0.1556, 0.1583, 0.1611, 0.1639, 0.1667]},
	"skill3": {"n": 28, "w": [0.1111, 0.1111, 0.1111, 0.1111, 0.1111, 0.1111, 0.1111, 0.1111, 0.1111, 0.1111, 0.1111, 0.1111, 0.1111, 0.1111, 0.1111, 0.1111, 0.1111, 0.1111, 0.1111, 0.1111, 0.1111, 0.1111, 0.1111, 0.1111, 0.1111, 0.1111, 0.1111, 0.1111]},
	"dodge": {"n": 16, "w": [0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2]},
	"hurt": {"n": 19, "w": [0.1, 0.1111, 0.1222, 0.1333, 0.1444, 0.1556, 0.1667, 0.1667, 0.1667, 0.1667, 0.1667, 0.1667, 0.1667, 0.1667, 0.1667, 0.1667, 0.1667, 0.1667, 0.1667]}
}
const ANIMS_ARCHER := {
	"idle": {"n": 48},
	"run": {"n": 32},
	"jump": {"n": 16},
	"atk1": {"n": 37, "w": [0.1333, 0.1444, 0.1556, 0.1667, 0.1778, 0.1889, 0.2, 0.1917, 0.1833, 0.175, 0.1667, 0.1583, 0.15, 0.1389, 0.1278, 0.1167, 0.1056, 0.0944, 0.0833, 0.0917, 0.1, 0.1083, 0.1167, 0.125, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1389, 0.1444, 0.15, 0.1556, 0.1611, 0.1667]},
	"atk2": {"n": 37, "w": [0.1333, 0.1444, 0.1556, 0.1667, 0.1778, 0.1889, 0.2, 0.1917, 0.1833, 0.175, 0.1667, 0.1583, 0.15, 0.1389, 0.1278, 0.1167, 0.1056, 0.0944, 0.0833, 0.0917, 0.1, 0.1083, 0.1167, 0.125, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1389, 0.1444, 0.15, 0.1556, 0.1611, 0.1667]},
	"atk3": {"n": 43, "w": [0.1333, 0.1361, 0.1389, 0.1417, 0.1444, 0.1472, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.1444, 0.1389, 0.1333, 0.1278, 0.1222, 0.1167, 0.1111, 0.1056, 0.1, 0.0944, 0.0889, 0.0833, 0.0917, 0.1, 0.1083, 0.1167, 0.125, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1389, 0.1444, 0.15, 0.1556, 0.1611, 0.1667]},
	"skill1": {"n": 43, "w": [0.1167, 0.1222, 0.1278, 0.1333, 0.1389, 0.1444, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.1417, 0.1333, 0.125, 0.1167, 0.1083, 0.1, 0.1056, 0.1111, 0.1167, 0.1222, 0.1278, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1389, 0.1444, 0.15, 0.1556, 0.1611, 0.1667]},
	"skill2": {"n": 46, "w": [0.2, 0.204, 0.208, 0.212, 0.216, 0.22, 0.204, 0.188, 0.172, 0.156, 0.14, 0.136, 0.132, 0.128, 0.124, 0.12, 0.12, 0.12, 0.12, 0.12, 0.12, 0.124, 0.128, 0.132, 0.136, 0.14, 0.14, 0.14, 0.14, 0.14, 0.14, 0.136, 0.132, 0.128, 0.124, 0.12, 0.12, 0.12, 0.12, 0.12, 0.12, 0.12, 0.12, 0.12, 0.12, 0.12]},
	"skill3": {"n": 43, "w": [0.1333, 0.1306, 0.1278, 0.125, 0.1222, 0.1194, 0.1167, 0.1167, 0.1167, 0.1167, 0.1167, 0.1167, 0.1167, 0.1167, 0.1167, 0.1167, 0.1167, 0.1167, 0.1167, 0.1167, 0.1167, 0.1167, 0.1167, 0.1167, 0.1167, 0.1194, 0.1222, 0.125, 0.1278, 0.1306, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333]},
	"dodge": {"n": 37, "w": [0.1167, 0.1194, 0.1222, 0.125, 0.1278, 0.1306, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333, 0.1333]},
	"hurt": {"n": 19, "w": [0.1, 0.1111, 0.1222, 0.1333, 0.1444, 0.1556, 0.1667, 0.1667, 0.1667, 0.1667, 0.1667, 0.1667, 0.1667, 0.1667, 0.1667, 0.1667, 0.1667, 0.1667, 0.1667]}
}
var ANIMS: Dictionary = {}
const RUN_CYCLE := 0.5
const IDLE_CYCLE := 0.8
var anim_on := false
var anim_tex: Dictionary = {}
var anim_spr: Sprite2D
var anim_cur := ""
var act_name := ""
var act_t := 0.0
var act_dur := 0.0
var loc_t := 0.0
var cast_cfg: Dictionary = {}
var has_art := false
var art: Node2D
var spr_wings: Sprite2D
var spr_body: Sprite2D
var spr_weapon: Sprite2D

func setup(main_ref, class_id: String, profile: Dictionary) -> void:
	main = main_ref
	cls = Data.classes[class_id]
	level = int(profile.level)
	st = Data.calc_stats(class_id)
	max_hp = float(st.hp)
	hp = max_hp
	energy = float(st.energy)
	collision_layer = 2
	collision_mask = 1
	z_index = 10
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = SIZE
	cs.shape = sh
	add_child(cs)
	body = ColorRect.new()
	body.size = SIZE
	body.position = -SIZE / 2.0
	body.color = Color.html(cls.color)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)
	_build_art(class_id)
	weapon = ColorRect.new()
	weapon.size = Vector2(28, 8)
	weapon.color = Color(0.9, 0.9, 0.9)
	weapon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(weapon)
	aura = ColorRect.new()
	aura.size = SIZE + Vector2(20, 20)
	aura.position = -aura.size / 2.0
	aura.color = Color(0.4, 0.9, 1.0, 0.35)
	aura.visible = false
	aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(aura)
	cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_bottom = 720
	add_child(cam)
	cam.make_current()
	if ResourceLoader.exists("res://fx_light.png"):
		light = PointLight2D.new()
		light.texture = load("res://fx_light.png")
		light.texture_scale = 2.6
		light.energy = 0.9
		light.color = Color(1.0, 0.82, 0.66)
		light.position = Vector2(0, -24)
		add_child(light)

func _build_art(class_id: String) -> void:
	if not CAST.has(class_id):
		return
	var c: Dictionary = CAST[class_id]
	var files: Array = [class_id + "_body", str(c.weapon)]
	if c.wings:
		files.append(class_id + "_wings")
	for f in files:
		if not ResourceLoader.exists("res://%s.png" % f):
			return
	cast_cfg = c
	has_art = true
	body.visible = false
	art = Node2D.new()
	art.position = Vector2(0.0, SIZE.y / 2.0)   # origem nos pés
	add_child(art)
	if c.wings:
		spr_wings = Sprite2D.new()
		spr_wings.texture = load("res://%s_wings.png" % class_id)
		spr_wings.scale = Vector2(ART_K, ART_K)
		spr_wings.position = Vector2(0.0, -47.1)
		art.add_child(spr_wings)
	spr_body = Sprite2D.new()
	spr_body.texture = load("res://%s_body.png" % class_id)
	spr_body.scale = Vector2(ART_K, ART_K)
	spr_body.position = Vector2(0.0, -45.5)
	art.add_child(spr_body)
	spr_weapon = Sprite2D.new()
	spr_weapon.texture = load("res://%s.png" % str(c.weapon))
	spr_weapon.centered = false
	var pv: Vector2 = c.pivot
	spr_weapon.offset = -pv
	var ws: float = float(c.wscale)
	spr_weapon.scale = Vector2(ws, ws)
	var wp: Vector2 = c.wpos
	spr_weapon.position = wp
	art.add_child(spr_weapon)
	_build_anim(class_id)

func _build_anim(class_id: String) -> void:
	if not ANIM_CLASSES.has(class_id):
		return
	match class_id:
		"mage":
			ANIMS = ANIMS_MAGE
		"archer":
			ANIMS = ANIMS_ARCHER
		_:
			ANIMS = ANIMS_WARRIOR
	for n in ANIMS:
		var path := "res://%s_%s.png" % [class_id, n]
		if not ResourceLoader.exists(path):
			anim_tex.clear()
			return
		anim_tex[n] = load(path)
	anim_spr = Sprite2D.new()
	anim_spr.scale = Vector2(ART_K, ART_K)
	anim_spr.position = Vector2(0.0, -69.5)
	art.add_child(anim_spr)
	anim_on = true
	spr_body.visible = false
	spr_weapon.visible = false
	if spr_wings != null:
		spr_wings.visible = false

func _act(n: String, dur: float) -> void:
	if anim_on and anim_tex.has(n):
		act_name = n
		act_t = 0.0
		act_dur = maxf(dur, 0.05)

func _update_anim(delta: float) -> void:
	loc_t += delta
	var nm := ""
	var fr := 0
	if act_name != "" and act_t < act_dur:
		act_t += delta
		nm = act_name
		var ws: Array = ANIMS[nm].w
		var tot := 0.0
		for w in ws:
			tot += float(w)
		var target := clampf(act_t / act_dur, 0.0, 0.999) * tot
		var acc := 0.0
		for i in ws.size():
			acc += float(ws[i])
			if target < acc:
				fr = i
				break
	else:
		act_name = ""
		if not is_on_floor():
			nm = "jump"
			fr = clampi(int((velocity.y + JUMP_V) / (2.0 * JUMP_V) * float(ANIMS["jump"].n)), 0, int(ANIMS["jump"].n) - 1)
		elif absf(velocity.x) > 20.0:
			nm = "run"
			fr = int(loc_t / RUN_CYCLE * float(ANIMS["run"].n)) % int(ANIMS["run"].n)
		else:
			nm = "idle"
			fr = int(loc_t / IDLE_CYCLE * float(ANIMS["idle"].n)) % int(ANIMS["idle"].n)
	if nm != anim_cur:
		anim_cur = nm
		anim_spr.texture = anim_tex[nm]
		var tsz: Vector2 = anim_tex[nm].get_size()
		anim_spr.hframes = maxi(1, int(tsz.x / 128.0))
		anim_spr.vframes = maxi(1, int(tsz.y / 112.0))
	anim_spr.frame = fr

func _process(delta: float) -> void:
	if anim_on and anim_spr != null:
		_update_anim(delta)

func _update_art(blink: bool) -> void:
	if anim_on:
		art.scale = Vector2(float(facing), 1.0)
		art.rotation = 0.0
		art.position.y = SIZE.y / 2.0
		art.modulate.a = 0.45 if blink else 1.0
		return
	var t := Time.get_ticks_msec() / 1000.0
	var moving := absf(velocity.x) > 20.0 and is_on_floor()
	var k := clampf(absf(velocity.y) / 4000.0, 0.0, 0.12)
	art.scale = Vector2(float(facing) * (1.0 - k), 1.0 + k + sin(t * 3.0) * 0.012)
	art.rotation = signf(velocity.x) * 0.07 if moving else 0.0
	art.position.y = SIZE.y / 2.0 - (absf(sin(t * 12.0)) * 3.0 if moving else 0.0)
	if spr_wings != null:
		var rate := 14.0 if not is_on_floor() else 4.0
		spr_wings.scale = Vector2(ART_K * (1.0 + 0.05 * sin(t * rate)), ART_K * (1.0 + 0.10 * sin(t * rate)))
	var ang: float = float(cast_cfg.idle)
	if lock > 0.0:
		ang = lerpf(float(cast_cfg.a0), float(cast_cfg.a1), 1.0 - clampf(lock / 0.35, 0.0, 1.0))
	spr_weapon.rotation_degrees = ang
	art.modulate.a = 0.45 if blink else 1.0

func get_rect() -> Rect2:
	return Rect2(global_position - SIZE / 2.0, SIZE)

func reset_to(pos: Vector2) -> void:
	position = pos
	velocity = Vector2.ZERO
	pending.clear()
	lock = 0.0
	dash_t = 0.0
	cam.reset_smoothing()

func respawn(pos: Vector2) -> void:
	dead = false
	visible = true
	hp = max_hp * 0.6
	energy = float(st.energy)
	invuln = 2.0
	reset_to(pos)

func _physics_process(delta: float) -> void:
	if dead or main.state != "mission":
		return
	_timers(delta)
	var on_floor := is_on_floor()
	coyote = 0.1 if on_floor else coyote - delta
	if not on_floor:
		velocity.y += GRAVITY * delta
	var dir := Input.get_axis("move_left", "move_right")
	if dash_t > 0.0:
		velocity.x = dash_v
		velocity.y = 0.0
		_dash_hits()
	elif lock > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)
	else:
		velocity.x = dir * float(st.speed)
		if dir != 0.0:
			facing = int(signf(dir))
	if Input.is_action_just_pressed("jump"):
		buffer_jump = 0.12
	if buffer_jump > 0.0 and coyote > 0.0 and dash_t <= 0.0:
		velocity.y = -JUMP_V
		coyote = 0.0
		buffer_jump = 0.0
	if Input.is_action_just_released("jump") and velocity.y < -200.0:
		velocity.y *= 0.5
	if Input.is_action_just_pressed("attack"):
		buffer_atk = 0.2
	if Input.is_action_just_pressed("dodge") and dodge_cd <= 0.0 and dash_t <= 0.0:
		_dodge()
	for i in 3:
		if Input.is_action_just_pressed("skill%d" % (i + 1)):
			_skill(i)
	if buffer_atk > 0.0 and lock <= 0.0 and dash_t <= 0.0:
		buffer_atk = 0.0
		_basic()
	energy = minf(float(st.energy), energy + float(st.regen) * delta)
	move_and_slide()
	_update_visual()

func _timers(delta: float) -> void:
	for i in 3:
		cds[i] = maxf(0.0, cds[i] - delta)
	dodge_cd = maxf(0.0, dodge_cd - delta)
	lock = maxf(0.0, lock - delta)
	buffer_atk -= delta
	buffer_jump -= delta
	invuln -= delta
	shield_t -= delta
	dash_t -= delta
	combo_timer -= delta
	if combo_timer <= 0.0:
		combo_idx = 0
	var due: Array = []
	for p in pending:
		p.t -= delta
		if p.t <= 0.0:
			due.append(p)
	if not due.is_empty():
		pending = pending.filter(func(x): return x.t > 0.0)
		for p in due:
			p.fn.call()

# ---------- Ataques ----------
func _face_input() -> void:
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		facing = int(signf(dir))

func _basic() -> void:
	var steps: Array = cls.combo
	var step: Dictionary = steps[combo_idx]
	_face_input()
	_act("atk%d" % (combo_idx + 1), float(step.dur))
	lock = float(step.dur)
	combo_timer = float(step.dur) + float(cls.reset)
	combo_idx = (combo_idx + 1) % steps.size()
	velocity.x = facing * float(step.get("adv", 0))
	pending.append({"t": float(step.startup), "fn": func(): _do_hit(step)})

func _do_hit(s: Dictionary) -> void:
	if dead:
		return
	match s.type:
		"melee":
			_melee(s)
		"projectile":
			_shoot(s)
		"aoe":
			_aoe(s)

func _roll(mult: float) -> Array:
	var d: float = float(st.atk) * mult * randf_range(0.92, 1.08)
	var crit := randf() * 100.0 < minf(float(st.crit), 60.0)
	if crit:
		d *= 1.6
	return [d, crit]

func _damage_rect(rect: Rect2, s: Dictionary) -> void:
	var hit := false
	for e in get_tree().get_nodes_in_group("enemies"):
		if rect.intersects(e.get_rect()):
			var r := _roll(float(s.dmg))
			e.take_hit(r[0], signf(e.global_position.x - global_position.x), float(s.get("kb", 100)), r[1], s.get("launch", false))
			hit = true
	if hit:
		main.hitstop(0.08 if float(s.dmg) > 1.5 else 0.04)

func _melee(s: Dictionary) -> void:
	var rng: float = float(s.range)
	var rect: Rect2
	if s.get("both", false):
		rect = Rect2(global_position + Vector2(-rng, -45), Vector2(rng * 2.0, 90))
	elif facing > 0:
		rect = Rect2(global_position + Vector2(0, -45), Vector2(rng, 90))
	else:
		rect = Rect2(global_position + Vector2(-rng, -45), Vector2(rng, 90))
	main.spawn_fx(rect, Color(1, 1, 1, 0.35), 0.12)
	_damage_rect(rect, s)

func _aoe(s: Dictionary) -> void:
	var c := global_position + Vector2(facing * float(s.ox), 0)
	var rect := Rect2(c - Vector2(float(s.w), float(s.h)) / 2.0, Vector2(float(s.w), float(s.h)))
	main.spawn_fx(rect, Color.html(cls.color).lightened(0.3) * Color(1, 1, 1, 0.5), 0.25)
	_damage_rect(rect, s)

func _shoot(s: Dictionary) -> void:
	var cnt := int(s.get("count", 1))
	var spread := float(s.get("spread", 0.0))
	for i in cnt:
		var ang := (i - (cnt - 1) / 2.0) * spread
		var p := preload("res://scripts/projectile.gd").new()
		p.main = main
		p.team = "player"
		p.vel = Vector2(facing * float(s.speed), 0.0).rotated(ang * facing)
		var r := _roll(float(s.dmg))
		p.dmg = r[0]
		p.crit = r[1]
		p.pierce = int(s.get("pierce", 0))
		p.radius = float(s.get("radius", 0.0))
		p.kb = float(s.get("kb", 60))
		p.col = Color.html(cls.color).lightened(0.35)
		p.size = Vector2(float(s.get("pw", 26)), float(s.get("ph", 10)))
		p.position = global_position + Vector2(facing * 24.0, -8.0)
		main.room_node.add_child(p)

# ---------- Habilidades e esquiva ----------
func _skill(i: int) -> void:
	if i >= cls.skills.size() or dash_t > 0.0:
		return
	var s: Dictionary = cls.skills[i]
	if level < int(s.unlock):
		main.toast("%s libera no nível %d" % [s.name, int(s.unlock)])
		return
	if cds[i] > 0.0 or energy < float(s.cost):
		return
	energy -= float(s.cost)
	cds[i] = float(s.cd)
	_face_input()
	pending.clear()
	match s.type:
		"melee", "projectile", "aoe":
			lock = float(s.get("dur", 0.4))
			_act("skill%d" % (i + 1), lock)
			pending.append({"t": float(s.get("startup", 0.1)), "fn": func(): _do_hit(s)})
		"dash":
			dash_t = float(s.dur)
			_act("skill%d" % (i + 1), float(s.dur))
			dash_v = facing * float(s.dist) / float(s.dur)
			dash_hit = s
			dash_list = []
			invuln = maxf(invuln, float(s.dur) * 0.6)
			lock = float(s.dur)
		"backstep":
			dash_t = 0.2
			dash_v = -facing * float(s.dist) / 0.2
			dash_hit = {}
			invuln = maxf(invuln, 0.35)
			lock = 0.2
		"shield":
			shield_t = float(s.duration)
			_act("skill%d" % (i + 1), 0.4)
			main.spawn_text(global_position + Vector2(0, -50), "Escudo!", Color(0.5, 0.95, 1.0), 24)

func _dodge() -> void:
	_face_input()
	dash_t = 0.22
	_act("dodge", 0.22)
	dash_v = facing * 590.0
	dash_hit = {}
	invuln = maxf(invuln, 0.3)
	dodge_cd = 0.9
	lock = 0.22
	pending.clear()

func _dash_hits() -> void:
	if dash_hit.is_empty():
		return
	var r := get_rect().grow(10.0)
	for e in get_tree().get_nodes_in_group("enemies"):
		if dash_list.has(e):
			continue
		if r.intersects(e.get_rect()):
			dash_list.append(e)
			var rr := _roll(float(dash_hit.dmg))
			e.take_hit(rr[0], float(facing), float(dash_hit.get("kb", 200)), rr[1], false)
			main.hitstop(0.06)

# ---------- Dano ----------
func take_hit(raw: float, from_x: float, kb: float = 150.0) -> void:
	if dead or invuln > 0.0 or main.state != "mission":
		return
	var d: float = raw * (1.0 - float(st.def) / (float(st.def) + 60.0))
	if shield_t > 0.0:
		d *= 0.25
	hp -= d
	invuln = 0.7 if shield_t <= 0.0 else 0.35
	main.hits_taken += 1
	main.combo = 0
	main.shake(6.0, 0.25)
	main.spawn_sparks(global_position + Vector2(0, -30), Color(0.7, 0.05, 0.08), 10)
	main.spawn_text(global_position + Vector2(0, -50), str(int(d)), Color(1, 0.3, 0.3), 26)
	var dirn := signf(global_position.x - from_x)
	if dirn == 0.0:
		dirn = 1.0
	velocity.x = dirn * kb
	lock = 0.2
	_act("hurt", 0.25)
	pending.clear()
	if hp <= 0.0:
		hp = 0.0
		dead = true
		visible = false
		main.on_player_died()

func _update_visual() -> void:
	weapon.position = Vector2(14.0 if facing > 0 else -42.0, -4.0)
	weapon.color = Color(1, 0.95, 0.5) if lock > 0.0 else Color(0.9, 0.9, 0.9)
	aura.visible = shield_t > 0.0
	var blink := invuln > 0.0 and int(Time.get_ticks_msec() / 80) % 2 == 0
	body.modulate.a = 0.45 if blink else 1.0
	weapon.visible = not has_art
	if has_art:
		_update_art(blink)
	if light != null:
		var tl := Time.get_ticks_msec() / 1000.0
		light.energy = (1.5 if lock > 0.0 else 0.9) + sin(tl * 7.0) * 0.04
		light.color = Color(1.0, 0.5, 0.42) if lock > 0.0 else Color(1.0, 0.82, 0.66)
