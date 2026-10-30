class_name Inventario
extends RefCounted
## Cuadrícula de casillas (cada una guarda una `Pila`) con un límite de peso.

signal cambiado

const CASILLAS := 20
const EPSILON := 0.0001

var casillas: Array[Pila] = []
## Límite de peso fijo; se usa si `limite_peso` no está asignado.
var peso_maximo := 100.0
## Opcional: () -> float. Permite que el límite dependa de la fuerza.
var limite_peso := Callable()


func _init(capacidad: int = CASILLAS) -> void:
	casillas.resize(capacidad)


func carga_maxima() -> float:
	return limite_peso.call() if limite_peso.is_valid() else peso_maximo


func peso_total() -> float:
	var total := 0.0
	for p in casillas:
		if p:
			total += p.peso()
	return total


func cantidad_de(objeto: FichaObjeto) -> int:
	var total := 0
	for p in casillas:
		if p and p.objeto == objeto:
			total += p.cantidad
	return total


## Agrega lo que quepa (por espacio y por peso). Devuelve la cantidad que NO cupo.
func agregar(objeto: FichaObjeto, cantidad: int = 1) -> int:
	var por_peso := cantidad
	if objeto.peso > 0.0:
		var libre := carga_maxima() - peso_total()
		por_peso = mini(cantidad, floori(libre / objeto.peso + EPSILON))
	var restante := maxi(0, por_peso)
	for p in casillas:
		if restante == 0:
			break
		if p and p.objeto == objeto and p.cantidad < objeto.max_pila:
			var n := mini(restante, objeto.max_pila - p.cantidad)
			p.cantidad += n
			restante -= n
	for i in casillas.size():
		if restante == 0:
			break
		if casillas[i] == null:
			var n := mini(restante, objeto.max_pila)
			casillas[i] = Pila.new(objeto, n)
			restante -= n
	var agregados := maxi(0, por_peso) - restante
	if agregados > 0:
		cambiado.emit()
	return cantidad - agregados


## Saca `cantidad` de una casilla (todo si es -1). Devuelve lo que sacó, o null.
func quitar(indice: int, cantidad: int = -1) -> Pila:
	var p := casillas[indice]
	if p == null:
		return null
	var n := p.cantidad if cantidad < 0 else mini(cantidad, p.cantidad)
	p.cantidad -= n
	if p.cantidad == 0:
		casillas[indice] = null
	cambiado.emit()
	return Pila.new(p.objeto, n)


## Mueve una casilla a otra: junta si es el mismo objeto, si no las intercambia.
func mover(desde: int, hacia: int) -> void:
	if desde == hacia or casillas[desde] == null:
		return
	var a := casillas[desde]
	var b := casillas[hacia]
	if b and b.objeto == a.objeto and b.cantidad < b.objeto.max_pila:
		var n := mini(a.cantidad, b.objeto.max_pila - b.cantidad)
		b.cantidad += n
		a.cantidad -= n
		if a.cantidad == 0:
			casillas[desde] = null
	else:
		casillas[desde] = b
		casillas[hacia] = a
	cambiado.emit()


## Índice de la primera casilla con un objeto que cumple `condicion(objeto)`, o -1.
func buscar(condicion: Callable) -> int:
	for i in casillas.size():
		if casillas[i] and condicion.call(casillas[i].objeto):
			return i
	return -1
