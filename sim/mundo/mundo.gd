class_name Mundo
extends RefCounted
## Estado completo de una partida: mapa, criaturas y reloj de ticks.
## El movimiento es continuo (`avanzar`), pero el combate y la IA ocurren en ticks
## de 1 segundo: en cada tick cada criatura piensa y ataca como máximo una vez.

signal criatura_agregada(criatura: Criatura)
signal ataque_resuelto(atacante: Criatura, defensor: Criatura, resultado: Combate.Resultado)

const DURACION_TICK := 1.0
const TICKS_REAPARECER_JUGADOR := 3
const TICKS_REAPARECER_ENEMIGO := 30

var mapa: Mapa
var buscador: BuscadorCamino
var dados: Dados
var criaturas: Array[Criatura] = []
var jugador: Criatura
var tick_actual := 0

var _acumulado := 0.0


func _init(p_mapa: Mapa, semilla: int = 0) -> void:
	mapa = p_mapa
	buscador = BuscadorCamino.new(mapa)
	dados = Dados.new(semilla)


static func distancia(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


## Sin casilla, aparece en el inicio del mapa ('J').
func crear_jugador(ficha: FichaCriatura, casilla := Vector2i(-1, -1)) -> Criatura:
	jugador = _crear(ficha, Criatura.Bando.JUGADOR, mapa.inicio if casilla == Vector2i(-1, -1) else casilla)
	return jugador


func crear_enemigo(ficha: FichaCriatura, casilla: Vector2i) -> Criatura:
	var c := _crear(ficha, Criatura.Bando.ENEMIGO, casilla)
	c.ia = IaCriatura.new()
	return c


## Crea un enemigo en cada casilla del mapa marcada con `simbolo` (p. ej. 'r' = rata).
func poblar(simbolo: String, ficha: FichaCriatura) -> Array[Criatura]:
	var creadas: Array[Criatura] = []
	for casilla in mapa.marcas.get(simbolo, []):
		creadas.append(crear_enemigo(ficha, casilla))
	return creadas


func _crear(ficha: FichaCriatura, bando: Criatura.Bando, casilla: Vector2i) -> Criatura:
	var c := Criatura.new(ficha, bando, mapa, buscador, casilla)
	# Callable a un método (no lambda) para no crear un ciclo de referencias Mundo ↔ Personaje.
	c.personaje.esta_ocupada = _ocupada_para
	criaturas.append(c)
	criatura_agregada.emit(c)
	return c


## Una casilla está ocupada si hay una criatura viva en ella (además de `excepto`).
func esta_ocupada(casilla: Vector2i, excepto: Criatura = null) -> bool:
	var c := criatura_en(casilla)
	return c != null and c != excepto


func _ocupada_para(casilla: Vector2i, personaje: Personaje) -> bool:
	var c := criatura_en(casilla)
	return c != null and c.personaje != personaje


func criatura_en(casilla: Vector2i) -> Criatura:
	for c in criaturas:
		if c.esta_vivo() and c.casilla == casilla:
			return c
	return null


## Cuerpo a cuerpo: casilla vecina (también en diagonal).
## A distancia: dentro del alcance del arma y con línea de vista.
func puede_atacar(atacante: Criatura, defensor: Criatura) -> bool:
	if not atacante.esta_vivo() or defensor == null or not defensor.esta_vivo():
		return false
	var d := distancia(atacante.casilla, defensor.casilla)
	if d > atacante.arma.alcance:
		return false
	return d <= 1 or mapa.linea_de_vision(atacante.casilla, defensor.casilla)


## Camino hacia el objetivo que termina en la primera casilla desde la que se le puede atacar.
func acercar(c: Criatura, hacia: Criatura) -> void:
	var otras: Array[Vector2i] = []
	for o in criaturas:
		if o != c and o != hacia and o.esta_vivo():
			otras.append(o.casilla)
	var ruta := buscador.camino(c.casilla, hacia.casilla, otras)
	var recorte: Array[Vector2i] = []
	for paso in ruta:
		if paso == hacia.casilla:
			break
		recorte.append(paso)
		var d := distancia(paso, hacia.casilla)
		if d <= 1 or (d <= c.arma.alcance and mapa.linea_de_vision(paso, hacia.casilla)):
			break
	c.personaje.seguir_ruta(recorte)


func avanzar(segundos: float) -> void:
	for c in criaturas:
		if c.esta_vivo():
			_perseguir(c)
			c.personaje.avanzar(segundos)
	_acumulado += segundos
	while _acumulado >= DURACION_TICK:
		_acumulado -= DURACION_TICK
		tick()


func tick() -> void:
	tick_actual += 1
	for c in criaturas:
		if not c.esta_vivo():
			_contar_reaparicion(c)
			continue
		if c.ia:
			c.ia.pensar(c, self)
		c.combatiente.regenerar()
	for c in criaturas:
		if c.objetivo and not c.objetivo.esta_vivo():
			c.olvidar_objetivo()
		if c.objetivo and puede_atacar(c, c.objetivo):
			var defensor := c.objetivo
			var r := Combate.resolver(c.combatiente, c.arma, defensor.combatiente, dados)
			ataque_resuelto.emit(c, defensor, r)


func _perseguir(c: Criatura) -> void:
	if not c.perseguir or c.objetivo == null or not c.objetivo.esta_vivo():
		return
	if puede_atacar(c, c.objetivo):
		c.personaje.cancelar_ruta()
	elif not c.personaje.esta_caminando():
		acercar(c, c.objetivo)


func _contar_reaparicion(c: Criatura) -> void:
	c.ticks_muerto += 1
	var espera := TICKS_REAPARECER_JUGADOR if c.bando == Criatura.Bando.JUGADOR else TICKS_REAPARECER_ENEMIGO
	if c.ticks_muerto >= espera and not esta_ocupada(c.origen):
		c.reaparecer()
