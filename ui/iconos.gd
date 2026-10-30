class_name Iconos
extends RefCounted
## Dibuja el icono de un objeto o habilidad: su textura si la tiene (la que pondrá el editor
## de contenido) o un placeholder con su color y la inicial de su nombre.


static func dibujar(lienzo: CanvasItem, objeto: FichaObjeto, rect: Rect2) -> void:
	dibujar_generico(lienzo, objeto.icono, objeto.color, objeto.nombre, rect)


static func dibujar_generico(lienzo: CanvasItem, icono: Texture2D, color: Color, nombre: String, rect: Rect2) -> void:
	if icono:
		lienzo.draw_texture_rect(icono, rect, false)
		return
	lienzo.draw_rect(rect.grow(-2), color.darkened(0.45))
	lienzo.draw_rect(rect.grow(-4), color)
	lienzo.draw_rect(Rect2(rect.position + Vector2(4, 4), Vector2(rect.size.x - 8, (rect.size.y - 8) * 0.35)), color.lightened(0.18))
	var fuente := ThemeDB.fallback_font
	var tamano := int(rect.size.y * 0.45)
	var inicial := nombre.substr(0, 1).to_upper()
	var base := rect.position + Vector2(0, rect.size.y * 0.5 + tamano * 0.35)
	lienzo.draw_string_outline(fuente, base, inicial, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, tamano, 3, Color(0, 0, 0, 0.8))
	lienzo.draw_string(fuente, base, inicial, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, tamano, Color.WHITE)
