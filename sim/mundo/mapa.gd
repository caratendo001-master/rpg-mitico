class_name Mapa
extends RefCounted
## Cuadrícula lógica del mundo: qué hay en cada casilla y por dónde se puede pasar.
## Es la fuente de verdad de las colisiones; la vista solo la dibuja.
## Formato de texto (una fila por línea):
##   '.' suelo   '#' muro   'O' columna   ' ' vacío (fuera del mapa jugable)

enum Tipo { VACIO, SUELO, MURO, COLUMNA }

const SIMBOLOS := {
	".": Tipo.SUELO,
	"#": Tipo.MURO,
	"O": Tipo.COLUMNA,
	" ": Tipo.VACIO,
}

const DIRECCIONES_8: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]

var ancho: int = 0
var alto: int = 0
var _casillas := PackedByteArray()


func _init(p_ancho: int = 0, p_alto: int = 0, relleno: Tipo = Tipo.VACIO) -> void:
	ancho = p_ancho
	alto = p_alto
	_casillas.resize(ancho * alto)
	_casillas.fill(relleno)


## Construye un mapa a partir de texto. Se ignoran las líneas en blanco al inicio y al final;
## las filas más cortas se rellenan con vacío.
static func desde_texto(texto: String) -> Mapa:
	var filas := texto.replace("\r", "").split("\n")
	while filas.size() > 0 and filas[filas.size() - 1].strip_edges() == "":
		filas.remove_at(filas.size() - 1)
	while filas.size() > 0 and filas[0].strip_edges() == "":
		filas.remove_at(0)
	var max_ancho := 0
	for fila in filas:
		max_ancho = maxi(max_ancho, fila.length())
	var mapa := Mapa.new(max_ancho, filas.size())
	for y in filas.size():
		var fila := filas[y]
		for x in fila.length():
			var simbolo := fila[x]
			assert(SIMBOLOS.has(simbolo), "Símbolo de mapa desconocido: '%s'" % simbolo)
			mapa.poner(Vector2i(x, y), SIMBOLOS.get(simbolo, Tipo.VACIO))
	return mapa


static func desde_archivo(ruta: String) -> Mapa:
	var texto := FileAccess.get_file_as_string(ruta)
	assert(texto != "", "No se pudo leer el mapa: %s" % ruta)
	return desde_texto(texto)


func esta_dentro(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < ancho and c.y < alto


func tipo_en(c: Vector2i) -> Tipo:
	if not esta_dentro(c):
		return Tipo.VACIO
	return _casillas[c.y * ancho + c.x] as Tipo


func poner(c: Vector2i, tipo: Tipo) -> void:
	assert(esta_dentro(c), "Casilla fuera del mapa: %s" % c)
	_casillas[c.y * ancho + c.x] = tipo


## Solo el suelo se puede pisar; muros, columnas y el vacío bloquean.
func es_transitable(c: Vector2i) -> bool:
	return tipo_en(c) == Tipo.SUELO


## Un paso de una casilla en cualquiera de las 8 direcciones.
## En diagonal no se puede "cortar esquinas": las dos casillas ortogonales
## que rodean el paso también deben estar libres.
func puede_moverse(desde: Vector2i, hacia: Vector2i) -> bool:
	var paso := hacia - desde
	if paso == Vector2i.ZERO or absi(paso.x) > 1 or absi(paso.y) > 1:
		return false
	if not es_transitable(hacia):
		return false
	if paso.x != 0 and paso.y != 0:
		return es_transitable(desde + Vector2i(paso.x, 0)) and es_transitable(desde + Vector2i(0, paso.y))
	return true


func vecinos_alcanzables(c: Vector2i) -> Array[Vector2i]:
	var vecinos: Array[Vector2i] = []
	for d in DIRECCIONES_8:
		if puede_moverse(c, c + d):
			vecinos.append(c + d)
	return vecinos


func casillas_de_tipo(tipo: Tipo) -> Array[Vector2i]:
	var resultado: Array[Vector2i] = []
	for y in alto:
		for x in ancho:
			if _casillas[y * ancho + x] == tipo:
				resultado.append(Vector2i(x, y))
	return resultado
