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
