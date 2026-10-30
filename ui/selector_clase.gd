class_name SelectorClase
extends ColorRect
## Pantalla inicial para elegir clase. Muestra la descripción, atributos y habilidades de
## cada ficha jugable y emite `elegida(ficha)`.

signal elegida(ficha: FichaCriatura)

var clases: Array[FichaCriatura] = []


func _ready() -> void:
	color = Color(0.06, 0.05, 0.08, 0.96)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centro := CenterContainer.new()
	add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 20)
	centro.add_child(caja)
	var titulo := Label.new()
	titulo.text = "Elige tu clase"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 34)
	caja.add_child(titulo)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 24)
	caja.add_child(fila)
	for ficha in clases:
		fila.add_child(_tarjeta(ficha))


func _tarjeta(ficha: FichaCriatura) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 0)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 10)
	panel.add_child(caja)
	var nombre := Label.new()
	nombre.text = ficha.nombre
	nombre.add_theme_font_size_override("font_size", 26)
	nombre.add_theme_color_override("font_color", ficha.color.lightened(0.35))
	caja.add_child(nombre)
	var descripcion := Label.new()
	descripcion.text = ficha.descripcion
	descripcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(descripcion)
	var c := Combatiente.new(ficha)
	var stats := Label.new()
	stats.text = "Vida %d · Maná %d · Defensa %d\nFUE %d  DES %d  CON %d  INT %d  SAB %d" % [
		c.vida_max, c.mana_max, c.defensa, ficha.fuerza, ficha.destreza, ficha.constitucion,
		ficha.inteligencia, ficha.sabiduria,
	]
	stats.modulate = Color(1, 1, 1, 0.8)
	caja.add_child(stats)
	for i in ficha.habilidades.size():
		var h := ficha.habilidades[i]
		var linea := Label.new()
		linea.text = "%d. %s — %s" % [i + 1, h.nombre, h.descripcion]
		linea.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		linea.add_theme_color_override("font_color", h.color.lightened(0.3))
		linea.add_theme_font_size_override("font_size", 14)
		caja.add_child(linea)
	var boton := Button.new()
	boton.text = "Jugar como %s" % ficha.nombre
	boton.custom_minimum_size = Vector2(0, 44)
	boton.pressed.connect(func() -> void: elegida.emit(ficha))
	caja.add_child(boton)
	return panel
