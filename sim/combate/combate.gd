class_name Combate
extends RefCounted
## Reglas de un ataque estilo D&D, calculadas siempre en la simulación:
## d20 + bonificación contra la defensa. 20 natural: impacto crítico (dobla los dados de daño).
## 1 natural: fallo seguro.


class Resultado:
	var impacta := false
	var critico := false
	var natural := 0
	var dano := 0
	## La habilidad usada, o null si fue el ataque normal del tick.
	var habilidad: FichaHabilidad


static func resolver(atacante: Combatiente, arma: FichaArma, defensor: Combatiente, dados: Dados) -> Resultado:
	var r := Resultado.new()
	var bonus := atacante.bonus_ataque(arma)
	r.natural = dados.d20()
	r.critico = r.natural == 20
	r.impacta = r.critico or (r.natural != 1 and r.natural + bonus >= defensor.defensa)
	if not r.impacta:
		defensor.esquivar()
		return r
	var tiradas := arma.dados * (2 if r.critico else 1)
	var total := 0
	for i in tiradas:
		total += dados.tirar(arma.caras)
	r.dano = maxi(1, total + bonus)
	defensor.recibir_dano(r.dano, r.critico)
	return r


## Ataque de una habilidad. Con arma: d20 + arma + bonus de la habilidad, y suma los dados del arma
## y los de la habilidad. Sin arma (hechizo): usa el atributo de la habilidad; si `siempre_impacta`,
## no tira d20.
static func resolver_habilidad(atacante: Combatiente, arma: FichaArma, habilidad: FichaHabilidad,
		defensor: Combatiente, dados: Dados) -> Resultado:
	var r := Resultado.new()
	r.habilidad = habilidad
	var mod := atacante.bonus_ataque(arma) if habilidad.usa_arma \
		else atacante.modificador(habilidad.atributo as Combatiente.Atributo)
	if habilidad.siempre_impacta:
		r.impacta = true
	else:
		r.natural = dados.d20()
		r.critico = r.natural == 20
		r.impacta = r.critico or (r.natural != 1 and r.natural + mod + habilidad.bonus_impacto >= defensor.defensa)
	if not r.impacta:
		defensor.esquivar()
		return r
	var multiplicador := 2 if r.critico else 1
	var total := 0
	if habilidad.usa_arma:
		for i in arma.dados * multiplicador:
			total += dados.tirar(arma.caras)
	for i in habilidad.dados * multiplicador:
		total += dados.tirar(habilidad.caras)
	r.dano = maxi(1, total + mod)
	defensor.recibir_dano(r.dano, r.critico)
	return r


## Curación de una habilidad: sus dados + el modificador de su atributo (mínimo 1).
static func curacion(lanzador: Combatiente, habilidad: FichaHabilidad, dados: Dados) -> int:
	var total := lanzador.modificador(habilidad.atributo as Combatiente.Atributo)
	for i in habilidad.dados:
		total += dados.tirar(habilidad.caras)
	return maxi(1, total)
