class_name Pila
extends RefCounted
## Una cantidad de un mismo objeto (una casilla del inventario o algo tirado en el suelo).

var objeto: FichaObjeto
var cantidad: int


func _init(p_objeto: FichaObjeto, p_cantidad: int = 1) -> void:
	objeto = p_objeto
	cantidad = p_cantidad


func peso() -> float:
	return objeto.peso * cantidad
