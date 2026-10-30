class_name Personaje
extends RefCounted
## Algo que camina por el mapa casilla a casilla (jugador; después también enemigos y NPCs).
## El tiempo lo da quien llama a `avanzar(segundos)`: en el cliente, el bucle de física;
## en el futuro, el servidor.
##
## Al empezar un paso, `casilla` pasa a ser la de destino (la casilla queda ocupada
## desde ese momento, como en Tibia). La vista interpola entre `paso_desde` y `casilla`
## con `fraccion_paso()`.

signal paso_iniciado(desde: Vector2i, hacia: Vector2i, duracion: float)

## Casillas por segundo en línea recta; en diagonal cada paso tarda √2 veces más.
var velocidad: float = 4.0
var casilla: Vector2i
var paso_desde: Vector2i

var _mapa: Mapa
var _buscador: BuscadorCamino
var _ruta: Array[Vector2i] = []
var _direccion := Vector2i.ZERO
var _paso_duracion := 0.0
var _paso_restante := 0.0


func _init(mapa: Mapa, buscador: BuscadorCamino, casilla_inicial: Vector2i) -> void:
	assert(mapa.es_transitable(casilla_inicial), "El personaje debe aparecer en suelo: %s" % casilla_inicial)
	_mapa = mapa
	_buscador = buscador
	casilla = casilla_inicial
	paso_desde = casilla_inicial


## Caminar hasta una casilla (clic). Devuelve false si no hay a dónde ir.
func ir_a(destino: Vector2i) -> bool:
	_ruta = _buscador.camino(casilla, destino)
	return not _ruta.is_empty()


## Dirección de teclado (cada componente -1, 0 o 1). Mientras no sea cero, el personaje
## sigue caminando en esa dirección y se cancela la ruta del clic.
func fijar_direccion(direccion: Vector2i) -> void:
	_direccion = direccion.clamp(Vector2i(-1, -1), Vector2i(1, 1))
	if _direccion != Vector2i.ZERO:
		_ruta.clear()


func detener() -> void:
	_ruta.clear()
	_direccion = Vector2i.ZERO


func esta_caminando() -> bool:
	return _paso_restante > 0.0


func ruta_pendiente() -> Array[Vector2i]:
	return _ruta.duplicate()


## 0 al empezar el paso, 1 al terminarlo (o si está quieto).
func fraccion_paso() -> float:
	if _paso_duracion <= 0.0:
		return 1.0
	return 1.0 - _paso_restante / _paso_duracion


func avanzar(segundos: float) -> void:
	assert(velocidad > 0.0, "La velocidad debe ser positiva")
	var tiempo := segundos
	while true:
		if _paso_restante > 0.0:
			var usado := minf(tiempo, _paso_restante)
			_paso_restante -= usado
			tiempo -= usado
			if _paso_restante > 0.0:
				return
		if not _iniciar_siguiente_paso():
			return
		if tiempo <= 0.0:
			return


func _iniciar_siguiente_paso() -> bool:
	var hacia: Variant = null
	if _direccion != Vector2i.ZERO:
		hacia = _paso_de_teclado(_direccion)
	elif not _ruta.is_empty():
		if _mapa.puede_moverse(casilla, _ruta[0]):
			hacia = _ruta.pop_front()
		else:
			_ruta.clear() # algo bloqueó el camino; se vuelve a pedir con otro clic
	if hacia == null:
		_paso_duracion = 0.0
		paso_desde = casilla
		return false
	paso_desde = casilla
	casilla = hacia
	var diagonal := paso_desde.x != casilla.x and paso_desde.y != casilla.y
	_paso_duracion = (sqrt(2.0) if diagonal else 1.0) / velocidad
	_paso_restante = _paso_duracion
	paso_iniciado.emit(paso_desde, casilla, _paso_duracion)
	return true


## Con teclado, si la diagonal está bloqueada se intenta deslizar por uno de sus ejes
## (así se puede caminar pegado a un muro sin atorarse).
func _paso_de_teclado(direccion: Vector2i) -> Variant:
	var candidatos: Array[Vector2i] = [direccion]
	if direccion.x != 0 and direccion.y != 0:
		candidatos.append(Vector2i(direccion.x, 0))
		candidatos.append(Vector2i(0, direccion.y))
	for d in candidatos:
		if _mapa.puede_moverse(casilla, casilla + d):
			return casilla + d
	return null
