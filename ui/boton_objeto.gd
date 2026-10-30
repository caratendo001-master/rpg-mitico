class_name BotonObjeto
extends Button
## Casilla de inventario o de equipo: muestra un objeto y su cantidad.
## Clic izquierdo emite `pressed`; clic derecho emite `clic_derecho`.

signal clic_derecho

var objeto: FichaObjeto
var cantidad := 0
## Texto tenue cuando está vacía (p. ej. "Cabeza" en las ranuras de equipo).
var etiqueta_vacia := ""


func _init() -> void:
	custom_minimum_size = Vector2(52, 52)
	focus_mode = Control.FOCUS_NONE


func mostrar(p_objeto: FichaObjeto, p_cantidad: int, ayuda: String) -> void:
	if objeto == p_objeto and cantidad == p_cantidad:
		return
	objeto = p_objeto
	cantidad = p_cantidad
	tooltip_text = (objeto.resumen() + "\n\n" + ayuda) if objeto else etiqueta_vacia
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		clic_derecho.emit()
		accept_event()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if objeto:
		Iconos.dibujar(self, objeto, rect.grow(-4))
		if cantidad > 1:
			var fuente := get_theme_default_font()
			var texto := str(cantidad)
			var base := Vector2(0, size.y - 6)
			draw_string_outline(fuente, base, texto, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 6, 13, 3, Color.BLACK)
			draw_string(fuente, base, texto, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 6, 13, Color.WHITE)
	elif etiqueta_vacia:
		draw_string(get_theme_default_font(), Vector2(0, size.y / 2 + 4), etiqueta_vacia,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 10, Color(1, 1, 1, 0.35))
