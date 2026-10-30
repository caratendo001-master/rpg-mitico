class_name Hud
extends Control
## Barras de vida y maná del jugador, arma equipada y aviso de muerte.
## Solo lee el estado de la simulación.

var jugador: Criatura

var _fuente: Font


func _ready() -> void:
	_fuente = get_theme_default_font()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if jugador == null:
		return
	var c := jugador.combatiente
	_barra(Vector2(16, 16), "Vida", c.vida, c.vida_max, Color("c0392b"))
	_barra(Vector2(16, 40), "Maná", c.mana, c.mana_max, Color("2e6fd1"))
	_barra_experiencia(Vector2(16, 62), c)
	var arma := jugador.arma
	var texto_arma := "%s  (%dd%d, alcance %d)" % [arma.nombre, arma.dados, arma.caras, arma.alcance]
	draw_string(_fuente, Vector2(16, 88), texto_arma, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.9, 0.9))
	if c.puntos_atributo > 0:
		var aviso := "¡Tienes 1 punto de atributo! (C)" if c.puntos_atributo == 1 \
			else "¡Tienes %d puntos de atributo! (C)" % c.puntos_atributo
		draw_string(_fuente, Vector2(230, 30), aviso,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.85, 0.3))
	if not jugador.esta_vivo():
		var centro := size / 2.0
		draw_rect(Rect2(0, centro.y - 40, size.x, 80), Color(0, 0, 0, 0.55))
		draw_string(_fuente, Vector2(0, centro.y - 4), "Has caído", HORIZONTAL_ALIGNMENT_CENTER, size.x, 32, Color(0.95, 0.3, 0.25))
		draw_string(_fuente, Vector2(0, centro.y + 26), "Reapareces en el inicio en unos segundos...", HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, Color(0.9, 0.9, 0.9))


func _barra_experiencia(pos: Vector2, c: Combatiente) -> void:
	var caja := Rect2(pos, Vector2(200, 8))
	draw_rect(caja.grow(1), Color(0, 0, 0, 0.75))
	draw_rect(Rect2(pos, Vector2(caja.size.x * c.progreso_nivel(), caja.size.y)), Color(0.85, 0.7, 0.2))
	draw_string(_fuente, pos + Vector2(206, 8), "Nivel %d" % c.nivel, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 0.9, 0.5))


func _barra(pos: Vector2, nombre: String, valor: int, maximo: int, color: Color) -> void:
	var caja := Rect2(pos, Vector2(200, 18))
	draw_rect(caja.grow(1), Color(0, 0, 0, 0.75))
	draw_rect(caja, color.darkened(0.6))
	if maximo > 0:
		draw_rect(Rect2(pos, Vector2(caja.size.x * float(valor) / maximo, caja.size.y)), color)
	draw_string(_fuente, pos + Vector2(6, 14), "%s %d / %d" % [nombre, valor, maximo], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
