class_name Mundo
extends RefCounted
## Estado completo de una partida: mapa, criaturas y reloj de ticks.
## El movimiento es continuo (`avanzar`), pero el combate y la IA ocurren en ticks
## de 1 segundo: en cada tick cada criatura piensa y ataca como máximo una vez.

signal criatura_agregada(criatura: Criatura)
signal ataque_resuelto(atacante: Criatura, defensor: Criatura, resultado: Combate.Resultado)
signal objeto_en_suelo(objeto: ObjetoSuelo)
signal objeto_retirado(objeto: ObjetoSuelo)
signal objeto_recogido(criatura: Criatura, objeto: FichaObjeto, cantidad: int)

const DURACION_TICK := 1.0
const TICKS_REAPARECER_JUGADOR := 3
const TICKS_REAPARECER_ENEMIGO := 30
## Lo que queda tirado desaparece tras este tiempo.
const TICKS_OBJETO_EN_SUELO := 120


## Objetos tirados en una casilla.
class ObjetoSuelo:
	var casilla: Vector2i
	var pila: Pila
	var ticks_restantes: int
	## false si el jugador lo acaba de tirar: no se recoge solo hasta que se aleje.
	var recogible := true

var mapa: Mapa
var buscador: BuscadorCamino
var dados: Dados
var criaturas: Array[Criatura] = []
var objetos_suelo: Array[ObjetoSuelo] = []
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
	c.murio.connect(_al_morir_criatura)
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


func objetos_en(casilla: Vector2i) -> Array[ObjetoSuelo]:
	var resultado: Array[ObjetoSuelo] = []
	for o in objetos_suelo:
		if o.casilla == casilla:
			resultado.append(o)
	return resultado


func soltar_en(casilla: Vector2i, pila: Pila) -> ObjetoSuelo:
	var o := ObjetoSuelo.new()
	o.casilla = casilla
	o.pila = pila
	o.ticks_restantes = TICKS_OBJETO_EN_SUELO
	objetos_suelo.append(o)
	objeto_en_suelo.emit(o)
	return o


## Tira al suelo, en su casilla, lo que la criatura tenga en una casilla del inventario.
func tirar_del_inventario(c: Criatura, indice: int) -> void:
	var pila := c.inventario.quitar(indice)
	if pila:
		soltar_en(c.casilla, pila).recogible = false


## Recoge todo lo que quepa de la casilla donde está la criatura.
func recoger(c: Criatura) -> void:
	for o in objetos_en(c.casilla):
		if not o.recogible:
			continue
		var no_cupo := c.inventario.agregar(o.pila.objeto, o.pila.cantidad)
		var recogidos := o.pila.cantidad - no_cupo
		if recogidos == 0:
			continue
		objeto_recogido.emit(c, o.pila.objeto, recogidos)
		o.pila.cantidad = no_cupo
		if no_cupo == 0:
			_retirar(o)


func _retirar(o: ObjetoSuelo) -> void:
	objetos_suelo.erase(o)
	objeto_retirado.emit(o)


func _al_morir_criatura(c: Criatura) -> void:
	if c.bando == Criatura.Bando.ENEMIGO and c.ficha.botin:
		for pila in c.ficha.botin.tirar(dados):
			soltar_en(c.casilla, pila)


func avanzar(segundos: float) -> void:
	for c in criaturas:
		if c.esta_vivo():
			_perseguir(c)
			c.personaje.avanzar(segundos)
	# El jugador recoge lo que pisa al detenerse sobre ello.
	if jugador and jugador.esta_vivo():
		for o in objetos_suelo:
			if not o.recogible and o.casilla != jugador.casilla:
				o.recogible = true
		if not jugador.personaje.esta_caminando() and not objetos_en(jugador.casilla).is_empty():
			recoger(jugador)
	_acumulado += segundos
	while _acumulado >= DURACION_TICK:
		_acumulado -= DURACION_TICK
		tick()


func tick() -> void:
	tick_actual += 1
	for o in objetos_suelo.duplicate():
		o.ticks_restantes -= 1
		if o.ticks_restantes <= 0:
			_retirar(o)
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
			# Quien da el golpe final se lleva la experiencia (solo el jugador progresa).
			if not defensor.esta_vivo() and c.bando == Criatura.Bando.JUGADOR:
				c.combatiente.ganar_experiencia(defensor.ficha.experiencia)


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
