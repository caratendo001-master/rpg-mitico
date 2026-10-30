class_name BarraHabilidades
extends HBoxContainer
## Barra de habilidades abajo al centro: icono, tecla, costo de maná y enfriamiento.
## Un clic (o la tecla 1, 2, 3) emite `usar(indice)`.

signal usar(indice: int)

var jugador: Criatura


class Casilla extends Button:
	var barra: BarraHabilidades
	var indice: int

	func _init(p_barra: BarraHabilidades, p_indice: int) -> void:
		barra = p_barra
		indice = p_indice
		custom_minimum_size = Vector2(60, 60)
		focus_mode = Control.FOCUS_NONE
		pressed.connect(func() -> void: barra.usar.emit(indice))

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var j := barra.jugador
		if j == null or indice >= j.habilidades.size():
			return
		var h := j.habilidades[indice]
		var rect := Rect2(Vector2.ZERO, size).grow(-4)
		Iconos.dibujar_generico(self, h.icono, h.color, h.nombre, rect)
		var fuente := get_theme_default_font()
		var restante := j.enfriamiento_de(h)
		if restante > 0.0:
			var fraccion := clampf(restante / maxf(h.enfriamiento, Mundo.ENFRIAMIENTO_GLOBAL), 0.0, 1.0)
			draw_rect(Rect2(rect.position, Vector2(rect.size.x, rect.size.y * fraccion)), Color(0, 0, 0, 0.6))
			if restante >= 1.0:
				_texto(fuente, Vector2(0, size.y / 2 + 7), "%d" % ceili(restante), HORIZONTAL_ALIGNMENT_CENTER, 20)
		if j.combatiente.mana < h.costo_mana:
			draw_rect(rect, Color(0.1, 0.1, 0.5, 0.45))
		_texto(fuente, Vector2(6, 16), str(indice + 1), HORIZONTAL_ALIGNMENT_LEFT, 13)
		_texto(fuente, Vector2(0, size.y - 6), "%d" % h.costo_mana, HORIZONTAL_ALIGNMENT_RIGHT, 12, Color(0.6, 0.8, 1))
		tooltip_text = h.resumen()

	func _texto(fuente: Font, pos: Vector2, texto: String, alineacion: HorizontalAlignment, tamano: int, color := Color.WHITE) -> void:
		draw_string_outline(fuente, pos, texto, alineacion, size.x - 6 if alineacion == HORIZONTAL_ALIGNMENT_RIGHT else size.x, tamano, 3, Color.BLACK)
		draw_string(fuente, pos, texto, alineacion, size.x - 6 if alineacion == HORIZONTAL_ALIGNMENT_RIGHT else size.x, tamano, color)


func configurar(p_jugador: Criatura) -> void:
	jugador = p_jugador
	for hijo in get_children():
		hijo.queue_free()
	for i in jugador.habilidades.size():
		add_child(Casilla.new(self, i))
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	var ancho := jugador.habilidades.size() * 66
	offset_left = -ancho / 2.0
	offset_right = ancho / 2.0
	offset_top = -112
	offset_bottom = -50
	add_theme_constant_override("separation", 6)
