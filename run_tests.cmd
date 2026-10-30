@echo off
:: Corre todas las pruebas de test/ con gdUnit4 en modo consola.
:: Requiere GODOT_BIN, por ejemplo: set GODOT_BIN=C:\Godot\Godot_v4.7.2-stable_win64_console.exe
cd /d "%~dp0"
if "%GODOT_BIN%"=="" (
    echo Define GODOT_BIN con la ruta a godot.exe ^(de preferencia la version _console.exe^).
    exit /b 1
)
:: La primera vez hay que importar el proyecto para que Godot registre las clases (class_name).
if not exist ".godot" "%GODOT_BIN%" --headless --path . --import
call addons\gdUnit4\runtest.cmd --godot_binary "%GODOT_BIN%" -a res://test --ignoreHeadlessMode
