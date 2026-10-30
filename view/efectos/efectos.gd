class_name Efectos
extends RefCounted
## Efectos visuales de un solo uso (proyectiles y ondas). Solo decoran: el resultado
## ya lo calculó la simulación.


## Esfera brillante que viaja de `desde` a `hacia` y luego llama `al_llegar`.
static func proyectil(padre: Node, desde: Vector2, hacia: Vector2, color: Color, al_llegar := Callable()) -> void:
	var p := _Dibujo.new(func(n: Node2D) -> void:
		n.draw_circle(Vector2.ZERO, 9, Color(color, 0.35))
		n.draw_circle(Vector2.ZERO, 5, color)
		n.draw_circle(Vector2.ZERO, 2, Color.WHITE))
	p.z_index = 150
	p.position = desde
	padre.add_child(p)
	var t := p.create_tween()
	t.tween_property(p, "position", hacia, clampf(desde.distance_to(hacia) / 900.0, 0.08, 0.35))
	if al_llegar.is_valid():
		t.tween_callback(al_llegar)
	t.tween_callback(p.queue_free)


## Anillo isométrico que se expande desde `centro` hasta cubrir `radio` casillas.
static func onda(padre: Node, centro: Vector2, radio: int, color: Color) -> void:
	var r_final := (radio + 0.5) * 64.0
	var onda_nodo := _Dibujo.new(func(n: Node2D) -> void:
		var r: float = n.get_meta("r", 1.0)
		var puntos := PackedVector2Array()
		for i in 33:
			var a := TAU * i / 32.0
			puntos.append(Vector2(cos(a) * r, sin(a) * r * 0.5))
		n.draw_polyline(puntos, color, 4.0)
		n.draw_colored_polygon(puntos.slice(0, 32), Color(color, 0.18)))
	onda_nodo.z_index = 140
	onda_nodo.position = centro
	onda_nodo.set_meta("r", 4.0)
	padre.add_child(onda_nodo)
	var t := onda_nodo.create_tween().set_parallel()
	t.tween_method(func(r: float) -> void:
		onda_nodo.set_meta("r", r)
		onda_nodo.queue_redraw(), 4.0, r_final, 0.3)
	t.tween_property(onda_nodo, "modulate:a", 0.0, 0.45).set_delay(0.15)
	t.chain().tween_callback(onda_nodo.queue_free)


class _Dibujo extends Node2D:
	var _pintar: Callable

	func _init(pintar: Callable) -> void:
		_pintar = pintar

	func _draw() -> void:
		_pintar.call(self)
