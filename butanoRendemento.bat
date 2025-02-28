@echo off
setlocal EnableDelayedExpansion
REM ============================================================
REM butanoRendemento.bat – Porque queremos FPS, non diapositivas
REM 
REM Este script mete un chute de esteroides no teu PC para xogos.
REM Fai backup do teu plan de enerxía, estados dos servizos 
REM e algúns axustes de Windows antes de aplicar o turbo modo.
REM Se lle metes "revert", revísao todo para que non sospeiten.
REM 
REM (Necesitas permisos de admin, non sexas parvo)
REM ============================================================

set backupFile=%~dp0GamingPerfBackup.json

if /I "%1"=="revert" goto revert

echo ====================================================
echo [🔥] FACENDO BACKUP POR SE LOGO TE ARREPINTES...
echo ====================================================

REM ---- 1. Gardar o plan de enerxía actual ----
for /f "tokens=2 delims=: " %%A in ('powercfg /getactivescheme') do (
    set currentPower=%%A
    goto :breakPP
)
:breakPP
if not defined currentPower (
    echo [❌] Non fun quen de atopar o plan de enerxía. Mala sorte.
    set currentPower=  
)
echo 🔋 Plan de enerxía actual: %currentPower%

REM ---- 2. Gardar o estado dos servizos molestos ----
for %%S in (SysMain DiagTrack WSearch) do (
    for /f "tokens=3" %%A in ('sc qc %%S ^| find "START_TYPE"') do (
        set stype=%%A
    )
    set stype=!stype: =!
    for /f "tokens=3" %%B in ('sc query %%S ^| find "STATE"') do (
        set sstatus=%%B
    )
    call :MapServiceStartup !stype! mapped
    set "Service_%%S=%mapped%|!sstatus!"
)
echo 💾 Servizos gardados. Se rompe algo, non digas que non avisei.

REM ---- 3. Gardar axustes do rexistro ----
for %%K in (
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects,VisualFXSetting"
    "HKCU\Control Panel\Desktop\WindowMetrics,MinAnimate"
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize,EnableTransparency"
    "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers,HwSchMode"
) do (
    for /f "tokens=1,2 delims=," %%P in (echo %%K) do (
        set "regPath=%%~P"
        set "regValueName=%%~Q"
    )
    for /f "tokens=3" %%V in ('reg query "%regPath%" /v "%regValueName%" 2^>nul ^| find "%regValueName%"') do (
        set "oldValue=%%V"
    )
    if not defined oldValue set "oldValue="
    set "Reg_%regValueName%=%oldValue%"
    set "oldValue="
)
echo 📝 Rexistro gardado. Agora xa podo empezar a meterlle chicha.

REM ---- 4. Gardar todo nun ficheiro ----
(
  echo PowerPlan=%currentPower%
  for %%S in (SysMain DiagTrack WSearch) do (
    call echo Service_%%S=%%Service_%%S%%
  )
  for %%V in (VisualFXSetting MinAnimate EnableTransparency HwSchMode) do (
    call echo Reg_%%V=%%Reg_%%V%%
  )
) > "%backupFile%"

echo ✅ Backup gardado en %backupFile%.

echo.
echo ====================================================
echo [🚀] ENCHENDO DE NITRO O TEU PC PARA OS XOGOS
echo ====================================================

REM ---- 5. Poñer o plan de enerxía máis bruto ----
powercfg /list | find "e9a42b02-d5df-448d-aa00-03f14749eb61" >nul
if errorlevel 1 (
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    echo 🔋 Poñendo High Performance. Agora o teu PC quenta máis ca o sol.
) else (
    powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61
    echo 🚀 Ultimate Performance activado. O teu procesador vai ir sen cinto de seguridade.
)

REM ---- 6. Desactivar servizos que non fan máis que roubar FPS ----
for %%S in (SysMain DiagTrack WSearch) do (
    sc config %%S start= disabled >nul
    net stop %%S >nul 2>&1
    echo 🛑 Servizo %%S desactivado. Agora non che vai frear os xogos.
)

REM ---- 7. Poñer os axustes "pro" no rexistro ----
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 1 /f >nul
echo ✨ VisualFXSetting configurado para rendemento máximo.
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul
echo 🏃 Animacións fóra, que non ralentizen nada.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul
echo 🚫 Transparencias desactivadas. Queremos FPS, non efectos bonitos.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f >nul
echo 🔥 Hardware Scheduling activado. Agora os gráficos van optimizados.

echo.
echo 🚀 Turbo modo activado. Se non notas a mellora, cambia de PC.
echo 🔄 Reinicia para que os cambios teñan o máximo efecto.
pause
goto :eof

:revert
echo ====================================================
echo [⏪] REVERTENDO TODO POR SE TE CAGACHES...
echo ====================================================

if not exist "%backupFile%" (
    echo [❌] Backup non atopado! Pois agora apáñate.
    pause
    goto :eof
)

REM ---- 1. Restaurar o plan de enerxía ----
if defined restorePower (
    powercfg /setactive %restorePower%
    echo 🔄 Plan de enerxía restaurado a %restorePower%.
) else (
    echo 🤷‍♂️ Non hai backup do plan de enerxía, quizais xa o queimaches.
)

REM ---- 2. Restaurar servizos ----
call :RestoreService SysMain %svcSys%
call :RestoreService DiagTrack %svcDiag%
call :RestoreService WSearch %svcWSearch%

REM ---- 3. Restaurar valores do rexistro ----
for %%V in (VisualFXSetting MinAnimate EnableTransparency HwSchMode) do (
    set "regVar=reg%%V"
    if defined !regVar! (
        reg add "!regVar!" /v %%V /t REG_DWORD /d !regVar! /f >nul
        echo 🔄 %%V restaurado a !regVar!.
    ) else (
        echo ❌ Non había backup para %%V, mala túa.
    )
)

echo.
echo 🔄 Todo restaurado. Agora parece que nunca fixeches nada.
pause
goto :eof

:MapServiceStartup
set "num=%1"
if "%num%"=="2" (
    set "%2=auto"
) else if "%num%"=="3" (
    set "%2=demand"
) else if "%num%"=="4" (
    set "%2=disabled"
) else (
    set "%2=auto"
)
goto :eof

:RestoreService
for /f "tokens=1,2 delims=|" %%A in ("%2%") do (
    set "stype=%%A"
    set "sstatus=%%B"
)
sc config %1% start= %stype% >nul
if /I "%sstatus%"=="RUNNING" (
    net start %1% >nul 2>&1
)
echo 🔄 Servizo %1% restaurado con inicio %stype% e estado %sstatus%.
goto :eof
