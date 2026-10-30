class_name IaCriatura
extends RefCounted
## Máquina de estados de un enemigo. Piensa una vez por tick.
##   PATRULLAR: deambula cerca de su origen.
##   PERSEGUIR: vio al jugador y camina hacia él.
##   ATACAR:    lo tiene a su alcance (el ataque lo resuelve `Mundo` en el tick).
##   REGRESAR:  se alejó demasiado de casa o el jugador murió; vuelve y se cura.

enum Estado { PATRULLAR, PERSEGUIR, ATACAR, REGRESAR }

var estado := Estado.PATRULLAR
## Casillas a las que ve al jugador (con línea de vista).
var radio_vision := 5
## Cuánto se aleja de su origen al patrullar.
var radio_patrulla := 3
## Si persiguiendo se aleja más que esto de su origen, se rinde y regresa.
var radio_correa := 9

var _ticks_espera := 0


func reiniciar() -> void:
	estado = Estado.PATRULLAR
	_ticks_espera = 0


## Alguien lo atacó (p. ej. desde lejos, fuera de su vista): deja de patrullar y va por él.
## Si está regresando a casa por la correa, lo ignora.
func provocar(yo: Criatura, atacante: Criatura) -> void:
	if estado == Estado.PATRULLAR:
		estado = Estado.PERSEGUIR
		yo.atacar(atacante)


func puede_ver(yo: Criatura, otra: Criatura, mundo: Mundo) -> bool:
	if otra == null or not otra.esta_vivo():
		return false
	return Mundo.distancia(yo.casilla, otra.casilla) <= radio_vision \
		and mundo.mapa.linea_de_vision(yo.casilla, otra.casilla)


func pensar(yo: Criatura, mundo: Mundo) -> void:
	var jugador := mundo.jugador
	match estado:
		Estado.PATRULLAR:
			if puede_ver(yo, jugador, mundo):
				estado = Estado.PERSEGUIR
				yo.atacar(jugador)
				_combatir(yo, jugador, mundo)
			else:
				_patrullar(yo, mundo)
		Estado.PERSEGUIR, Estado.ATACAR:
			_combatir(yo, jugador, mundo)
		Estado.REGRESAR:
			_regresar(yo)


func _combatir(yo: Criatura, jugador: Criatura, mundo: Mundo) -> void:
	if jugador == null or not jugador.esta_vivo() \
			or Mundo.distancia(yo.casilla, yo.origen) > radio_correa:
		estado = Estado.REGRESAR
		yo.olvidar_objetivo()
		_regresar(yo)
		return
	yo.atacar(jugador)
	estado = Estado.ATACAR if mundo.puede_atacar(yo, jugador) else Estado.PERSEGUIR


func _patrullar(yo: Criatura, mundo: Mundo) -> void:
	if yo.personaje.esta_caminando():
		return
	if _ticks_espera > 0:
		_ticks_espera -= 1
		return
	var lado := radio_patrulla * 2 + 1
	var destino := yo.origen + Vector2i(mundo.dados.tirar(lado) - radio_patrulla - 1, mundo.dados.tirar(lado) - radio_patrulla - 1)
	if mundo.mapa.es_transitable(destino) and not mundo.esta_ocupada(destino, yo):
		yo.personaje.ir_a(destino)
	_ticks_espera = 1 + mundo.dados.tirar(3)


func _regresar(yo: Criatura) -> void:
	if Mundo.distancia(yo.casilla, yo.origen) <= 1:
		yo.combatiente.restaurar()
		yo.personaje.cancelar_ruta()
		estado = Estado.PATRULLAR
	elif not yo.personaje.esta_caminando():
		yo.personaje.ir_a(yo.origen)
