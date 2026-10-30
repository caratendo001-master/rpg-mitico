extends GdUnitTestSuite
## Pruebas de atributos, vida y la tirada de ataque d20.


## Dados que devuelven valores preparados, para probar casos exactos.
class DadosFijos extends Dados:
	var valores: Array[int] = []

	func tirar(_caras: int) -> int:
		return valores.pop_front()


func _guerrero() -> FichaCriatura:
	return load("res://data/criaturas/guerrero.tres")


func _rata() -> FichaCriatura:
	return load("res://data/criaturas/rata_gigante.tres")


func test_modificadores_estilo_dnd() -> void:
	assert_int(FichaCriatura.modificador(10)).is_equal(0)
	assert_int(FichaCriatura.modificador(11)).is_equal(0)
	assert_int(FichaCriatura.modificador(14)).is_equal(2)
	assert_int(FichaCriatura.modificador(9)).is_equal(-1)
	assert_int(FichaCriatura.modificador(8)).is_equal(-1)
	assert_int(FichaCriatura.modificador(3)).is_equal(-4)


func test_valores_derivados_del_guerrero() -> void:
	var g := Combatiente.new(_guerrero())
	assert_int(g.vida_max).is_equal(34) # 30 + 2·(+2 con)
	assert_int(g.mana_max).is_equal(8) # 10 + 2·(-1 int)
	assert_int(g.defensa).is_equal(13) # 12 + (+1 des)
	assert_int(g.vida).is_equal(34)
	assert_int(g.bonus_ataque(load("res://data/armas/espada.tres"))).is_equal(2)
	assert_int(g.bonus_ataque(load("res://data/armas/arco.tres"))).is_equal(1)


func test_dano_y_muerte() -> void:
	var r := Combatiente.new(_rata())
	var muertes := [0]
	r.murio.connect(func() -> void: muertes[0] += 1)
	r.recibir_dano(5)
	assert_int(r.vida).is_equal(r.vida_max - 5)
	assert_bool(r.esta_vivo()).is_true()
	r.recibir_dano(50)
	assert_int(r.vida).is_equal(0)
	assert_bool(r.esta_vivo()).is_false()
	r.recibir_dano(5) # ya muerta: no vuelve a morir
	assert_int(muertes[0]).is_equal(1)


func test_curar_no_pasa_del_maximo_y_regenera() -> void:
	var g := Combatiente.new(_guerrero())
	g.recibir_dano(10)
	g.curar(4)
	assert_int(g.vida).is_equal(28)
	g.curar(100)
	assert_int(g.vida).is_equal(34)
	g.recibir_dano(5)
	g.mana = 0
	g.regenerar()
	assert_int(g.vida).is_equal(30) # regen_vida = 1
	assert_int(g.mana).is_equal(1)


func test_impacto_normal() -> void:
	var g := Combatiente.new(_guerrero())
	var r := Combatiente.new(_rata()) # defensa 11
	var dados := DadosFijos.new()
	dados.valores = [9, 5] # 9 + 2 = 11 ≥ 11 impacta; daño 5 + 2
	var res := Combate.resolver(g, g.ficha.arma, r, dados)
	assert_bool(res.impacta).is_true()
	assert_bool(res.critico).is_false()
	assert_int(res.dano).is_equal(7)
	assert_int(r.vida).is_equal(r.vida_max - 7)


func test_fallo_por_poco() -> void:
	var g := Combatiente.new(_guerrero())
	var r := Combatiente.new(_rata())
	var esquivas := [0]
	r.esquivo.connect(func() -> void: esquivas[0] += 1)
	var dados := DadosFijos.new()
	dados.valores = [8] # 8 + 2 = 10 < 11
	var res := Combate.resolver(g, g.ficha.arma, r, dados)
	assert_bool(res.impacta).is_false()
	assert_int(r.vida).is_equal(r.vida_max)
	assert_int(esquivas[0]).is_equal(1)


func test_20_natural_es_critico_y_dobla_dados() -> void:
	var r := Combatiente.new(_rata())
	var g := Combatiente.new(_guerrero())
	var dados := DadosFijos.new()
	dados.valores = [20, 3, 4] # dos dados de la mordida por el crítico
	var res := Combate.resolver(r, r.ficha.arma, g, dados)
	assert_bool(res.critico).is_true()
	assert_int(res.dano).is_equal(8) # 3 + 4 + 1 (des)


func test_1_natural_siempre_falla() -> void:
	var g := Combatiente.new(_guerrero())
	g.ficha = g.ficha.duplicate()
	g.ficha.fuerza = 40 # bonificación enorme
	var r := Combatiente.new(_rata())
	var dados := DadosFijos.new()
	dados.valores = [1]
	assert_bool(Combate.resolver(g, g.ficha.arma, r, dados).impacta).is_false()


func test_dano_minimo_es_1() -> void:
	var debil := _rata().duplicate()
	debil.destreza = 1 # modificador -5
	var r := Combatiente.new(debil)
	var g := Combatiente.new(_guerrero())
	var dados := DadosFijos.new()
	dados.valores = [20, 1, 1]
	assert_int(Combate.resolver(r, debil.arma, g, dados).dano).is_equal(1)
