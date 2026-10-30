class_name Equipo
extends RefCounted
## Objetos puestos, uno por ranura (cabeza, torso, manos, arma, escudo, anillo).
## Sus bonificaciones las lee `Combatiente` (defensa y atributos).

signal cambiado

var _ranuras := {} # FichaObjeto.Ranura -> FichaObjeto


func en(ranura: FichaObjeto.Ranura) -> FichaObjeto:
	return _ranuras.get(ranura)


## Pone un objeto sin pasar por el inventario (equipo inicial).
func poner(objeto: FichaObjeto) -> void:
	assert(objeto.es_equipable(), "%s no se puede equipar" % objeto.nombre)
	_ranuras[objeto.ranura] = objeto
	cambiado.emit()


## Equipa el objeto de una casilla del inventario; lo que había en esa ranura vuelve al inventario.
func equipar(inventario: Inventario, indice: int) -> bool:
	var pila := inventario.casillas[indice]
	if pila == null or not pila.objeto.es_equipable():
		return false
	var objeto := pila.objeto
	var anterior: FichaObjeto = _ranuras.get(objeto.ranura)
	inventario.quitar(indice, 1)
	if anterior and inventario.agregar(anterior) > 0:
		inventario.agregar(objeto) # no cupo lo anterior: se deshace
		return false
	_ranuras[objeto.ranura] = objeto
	cambiado.emit()
	return true


## Quita un objeto y lo guarda en el inventario. Falla si no cabe.
func desequipar(ranura: FichaObjeto.Ranura, inventario: Inventario) -> bool:
	var objeto: FichaObjeto = _ranuras.get(ranura)
	if objeto == null or inventario.agregar(objeto) > 0:
		return false
	_ranuras.erase(ranura)
	cambiado.emit()
	return true


func defensa() -> int:
	var total := 0
	for o in _ranuras.values():
		total += o.defensa
	return total


func bonus_atributo(atributo: int) -> int:
	var total := 0
	for o in _ranuras.values():
		total += o.bonus_atributo(atributo)
	return total
