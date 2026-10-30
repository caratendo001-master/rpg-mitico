# RPG Mítico — Godot 4 + GDScript

RPG de fantasía mítica en vista isométrica por casillas (inspiración: D&D, Project Zomboid, Tibia).
Primero vertical slice para un jugador; al final, mundo online persistente con servidor autoritativo.
Documento de diseño completo: `docs/DISENO.md`. Responder siempre en español.

## Regla de arquitectura (la más importante)

**Todo el estado del juego vive en `sim/` y nunca depende de nodos visuales.**
Posiciones, vida, maná, inventario, combate, IA, botín, misiones: todo es simulación.
Motivo: cuando llegue el multijugador, `sim/` se muda tal cual a un servidor autoritativo;
el cliente solo dibuja el estado y envía acciones del jugador.

Consecuencias prácticas:
- Las clases de `sim/` extienden `RefCounted` u `Object` (o `Resource` para datos). **Nunca** `Node`,
  `Node2D`, `Sprite2D`, etc., y nunca llaman a `get_tree()`, `get_node()`, `$...`, `Input`, `Engine`
  ni a la escena.
- `sim/` no conoce a `view/` ni a `ui/`. La dependencia va en un solo sentido: `view/` y `ui/` leen `sim/`.
- La simulación avanza por **ticks** (~1 s para combate) llamados desde fuera (`sim.tick()`); no usa
  `_process` ni temporizadores de nodos. Así el servidor puede correrla sin escena.
- Todo lo aleatorio (tiradas d20, botín) se calcula en `sim/` con un RNG con semilla (`Dados`),
  nunca en lo visual. Debe ser reproducible en pruebas.
- Las posiciones lógicas son **casillas** (`Vector2i`), no píxeles. Convertir casilla ↔ pantalla es
  trabajo de `view/`.
- La entrada del jugador se traduce en **acciones** (p. ej. "mover a casilla X", "atacar a Y") que se
  entregan a la simulación. Así después viajan por la red sin cambiar la lógica.
- Los nodos de `view/` reaccionan a señales o leen el estado; no modifican el estado directamente.

## Estructura

| Carpeta   | Contenido |
|-----------|-----------|
| `sim/`    | Lógica pura del juego (sin nodos). `sim/core/` utilidades base como `Dados`. |
| `view/`   | Escenas y nodos que dibujan el estado (mapa isométrico, sprites, cámara). Escena principal: `view/main.tscn`. |
| `data/`   | Objetos, enemigos y hechizos como Resources (`.tres`) o JSON. Balancear aquí, no en código. |
| `ui/`     | Interfaz: HUD, inventario, diálogos, menús. |
| `assets/` | Sprites, tiles, audio, fuentes. |
| `test/`   | Pruebas gdUnit4. `test/sim/` refleja la estructura de `sim/`. |
| `addons/gdUnit4/` | Framework de pruebas (v6.2.2). No editar. |
| `docs/`   | Documento de diseño. |
| `Ejecutable/` | Builds exportados (no se versionan). |

## Convenciones técnicas

- Godot 4.7 (estable), GDScript con tipado estático (`var x: int`, `:=`, tipos de retorno).
- Isométrico 2:1, tiles de 64×32 px, `TileMapLayer`. Pixel art: filtro de textura *Nearest* (ya configurado).
- Renderizador *Compatibility* (corre en PCs modestos y deja abierta la puerta a móvil).
- Nombres de clases y métodos en español, consistentes con el diseño (`Dados`, `tirada_impacto`).

## Pruebas

- Cada cambio en `sim/` lleva pruebas en `test/sim/` (`extends GdUnitTestSuite`, funciones `test_*`).
- Las pruebas de `sim/` no instancian escenas; si una prueba necesita una escena, la lógica está mal ubicada.
- Correr desde el editor: panel **GdUnit** → ejecutar todo. Desde consola: `run_tests.cmd`
  (requiere la variable `GODOT_BIN` apuntando a `godot.exe`).
- Godot 4.7.2 está en `GODOT/` (ignorado por Git): `Godot_v4.7.2-stable_win64.exe` (editor) y
  `Godot_v4.7.2-stable_win64_console.exe` (consola; usar este en `GODOT_BIN`).
- Los errores "Remote Debugger: Unable to connect to host '127.0.0.1:0'" al correr pruebas son esperados
  (gdUnit4 los provoca a propósito para evitar el depurador interactivo).
- Versionar los `.uid` y `.import` que genera Godot.

## Forma de trabajo

- Avanzar por las fases de `docs/DISENO.md`; no saltar de fase sin cumplir su criterio de terminado.
- Una tarea por sesión; commit al terminar cada tarea que funcione.

## Mundo y mapas

- `sim/mundo/mapa.gd` (`Mapa`): cuadrícula lógica y **fuente de verdad de las colisiones**.
  Solo el suelo es transitable; pasos de 1 casilla en 8 direcciones, sin cortar esquinas en diagonal
  (`puede_moverse`). Todo movimiento futuro (jugador, enemigos, A*) debe pasar por aquí.
- Los mapas son texto en `data/mapas/*.txt`: `.` suelo, `#` muro, `O` columna, espacio = vacío.
  Al exportar, agregar `*.txt` a los filtros de recursos no-Godot del preset de exportación.
- `sim/mundo/buscador_camino.gd` (`BuscadorCamino`): A* (`AStarGrid2D`) con las mismas reglas que
  `Mapa.puede_moverse`; si el destino está bloqueado, llega lo más cerca posible.
- `sim/entidades/personaje.gd` (`Personaje`): camina casilla a casilla con `ir_a()` (clic) o
  `fijar_direccion()` (teclado, se desliza por muros en diagonal). El tiempo entra por
  `avanzar(segundos)` desde `_physics_process`; ocupa la casilla destino al empezar cada paso.
- `view/mundo/mapa_vista.tscn` (`MapaVista`): dibuja el `Mapa` con `Suelo` y, dentro del nodo `Mundo`
  (y-sort), la capa `Bloques`. Todo lo que deba ordenarse en profundidad con muros y columnas
  (personajes, objetos) se agrega con `agregar_al_mundo()` con su origen en los pies.
- `view/entidades/personaje_vista.gd`: placeholder del personaje + contorno con `z_index` alto
  para verlo cuando un muro lo tapa. `view/camara_juego.gd`: sigue al jugador, zoom por pasos.
- `view/main.gd`: traduce entrada (clic, WASD/flechas en direcciones de pantalla) a acciones del `Personaje`.
- `view/mundo/tiles_placeholder.gd`: TileSet isométrico 64×32 con texturas generadas por código;
  se reemplazará por pixel art real con las mismas fuentes/coordenadas de atlas.

## Estado

- Fase 0 (cimientos): completa.
- Fase 1 (mundo y movimiento): completa, pendiente de que el usuario la pruebe jugando.
