class_name CriaturaVista
extends Node2D
## Dibuja una `Criatura` de la simulación (placeholder hasta tener sprites): cuerpo, barra de
## vida, anillo si es el objetivo del jugador, números de daño y muerte/reaparición.
## Su origen está en los pies, al centro de la casilla: eso es lo que usa el y-sort.

const COLOR_CABEZA := Color("e8c39e")
const COLOR_SOMBRA := Color(0, 0, 0, 0.35)
const COLOR_SILUETA := Color(1, 1, 1, 0.55)
const COLOR_OBJETIVO := Color(0.95, 0.2, 0.15, 0.9)

var criatura: Criatura
var mundo: Mundo
var mapa_vista: MapaVista

var _silueta: Node2D
var _embestida := Vector2.ZERO


func _init(p_criatura: Criatura, p_mundo: Mundo, p_mapa_vista: MapaVista) -> void:
	criatura = p_criatura
	mundo = p_mundo
	mapa_vista = p_mapa_vista
	name = criatura.ficha.nombre.replace(" ", "")


func _ready() -> void:
	if criatura.bando == Criatura.Bando.JUGADOR:
		# Contorno encima de todo: deja ver al jugador cuando un muro lo tapa.
		_silueta = Node2D.new()
		_silueta.z_index = 100
		_silueta.draw.connect(_dibujar_silueta)
		add_child(_silueta)
	criatura.combatiente.herido.connect(_al_ser_herido)
	criatura.combatiente.esquivo.connect(func() -> void: texto_flotante("falla", Color(0.8, 0.8, 0.8), 13))
	criatura.combatiente.murio.connect(_al_morir)
	criatura.combatiente.experiencia_ganada.connect(func(xp: int) -> void:
		texto_flotante("+%d XP" % xp, Color(0.95, 0.8, 0.3), 14))
	criatura.combatiente.subio_nivel.connect(func(n: int) -> void:
		texto_flotante("¡Nivel %d!" % n, Color(1, 0.9, 0.2), 26, -30.0))
	criatura.reaparecio.connect(_al_reaparecer)
	position = _posicion_en_pantalla()


func _process(_delta: float) -> void:
	position = _posicion_en_pantalla() + _embestida
	queue_redraw()


## Pequeño avance hacia el objetivo al atacar, para que se entienda quién golpea.
func embestir(hacia: Vector2) -> void:
	var direccion := (hacia - position).normalized() * 7.0
	var t := create_tween()
	t.tween_property(self, "_embestida", direccion, 0.07)
	t.tween_property(self, "_embestida", Vector2.ZERO, 0.12)


func _posicion_en_pantalla() -> Vector2:
	var p := criatura.personaje
	var desde := mapa_vista.casilla_a_local(p.paso_desde)
	var hacia := mapa_vista.casilla_a_local(p.casilla)
	return desde.lerp(hacia, p.fraccion_paso())


func _draw() -> void:
	var vivo := criatura.esta_vivo()
	if vivo and mundo.jugador and mundo.jugador.objetivo == criatura:
		_dibujar_elipse(Vector2.ZERO, Vector2(20, 10), COLOR_OBJETIVO, false)
	_dibujar_elipse(Vector2.ZERO, Vector2(13, 6) * maxf(criatura.ficha.tamano, 0.7), COLOR_SOMBRA, true)
	var color := criatura.ficha.color
	if criatura.ficha.tamano < 0.8:
		_dibujar_cuadrupedo(color)
	else:
		_dibujar_humanoide(color)
	if vivo:
		_dibujar_barra_vida()


func _dibujar_humanoide(color: Color) -> void:
	draw_rect(Rect2(-8, -34, 16, 30), color)
	draw_rect(Rect2(-8, -34, 5, 30), color.lightened(0.15))
	draw_circle(Vector2(0, -42), 8, COLOR_CABEZA)


## Rata y otras alimañas: cuerpo bajo y alargado, cabeza y cola.
func _dibujar_cuadrupedo(color: Color) -> void:
	_dibujar_elipse(Vector2(0, -7), Vector2(12, 7), color, true)
	_dibujar_elipse(Vector2(-3, -9), Vector2(7, 4), color.lightened(0.12), true)
	draw_circle(Vector2(11, -9), 5, color.darkened(0.1))
	draw_circle(Vector2(13, -11), 1.2, Color(0.9, 0.2, 0.2))
	draw_line(Vector2(-12, -6), Vector2(-22, -2), color.darkened(0.3), 2.0)


func _dibujar_barra_vida() -> void:
	var c := criatura.combatiente
	var es_jugador := criatura.bando == Criatura.Bando.JUGADOR
	if es_jugador and c.vida >= c.vida_max:
		return
	var alto := 52.0 if criatura.ficha.tamano >= 0.8 else 24.0
	var fraccion := float(c.vida) / c.vida_max
	var caja := Rect2(-15, -alto - 6, 30, 4)
	draw_rect(caja.grow(1), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(caja.position, Vector2(caja.size.x * fraccion, caja.size.y)), Color.RED.lerp(Color.LIME_GREEN, fraccion))


func _dibujar_silueta() -> void:
	if not criatura.esta_vivo():
		return
	_silueta.draw_rect(Rect2(-8, -34, 16, 30), COLOR_SILUETA, false, 1.0)
	_silueta.draw_arc(Vector2(0, -42), 8, 0, TAU, 20, COLOR_SILUETA, 1.0)


func _dibujar_elipse(centro: Vector2, radios: Vector2, color: Color, relleno: bool) -> void:
	var puntos := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		puntos.append(centro + Vector2(cos(a) * radios.x, sin(a) * radios.y))
	if relleno:
		draw_colored_polygon(puntos, color)
	else:
		puntos.append(puntos[0])
		draw_polyline(puntos, color, 2.0)


func _al_ser_herido(cantidad: int, critico: bool) -> void:
	var color := Color(1, 0.85, 0.2) if critico else Color(1, 0.3, 0.25)
	texto_flotante(("-%d!" if critico else "-%d") % cantidad, color, 20 if critico else 16)
	modulate = Color(1, 0.55, 0.55)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.25)


## Número o palabra que sube y se desvanece sobre la criatura.
func texto_flotante(texto: String, color: Color, tamano: int, desfase_y := 0.0) -> void:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.z_index = 200
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.add_theme_color_override("font_outline_color", Color.BLACK)
	etiqueta.add_theme_constant_override("outline_size", 4)
	etiqueta.add_theme_font_size_override("font_size", tamano)
	var alto := 60.0 if criatura.ficha.tamano >= 0.8 else 34.0
	etiqueta.position = Vector2(-12 + randf_range(-6, 6), -alto - 18 + desfase_y)
	add_child(etiqueta)
	var t := etiqueta.create_tween().set_parallel()
	t.tween_property(etiqueta, "position:y", etiqueta.position.y - 28, 0.9)
	t.tween_property(etiqueta, "modulate:a", 0.0, 0.9).set_delay(0.3)
	t.chain().tween_callback(etiqueta.queue_free)


func _al_morir() -> void:
	# El jugador queda como fantasma hasta reaparecer; los enemigos se desvanecen.
	var alfa := 0.3 if criatura.bando == Criatura.Bando.JUGADOR else 0.0
	create_tween().tween_property(self, "modulate:a", alfa, 0.6)


func _al_reaparecer() -> void:
	modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(self, "modulate:a", 1.0, 0.4)
