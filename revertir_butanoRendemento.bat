@echo off
setlocal EnableDelayedExpansion
REM ============================================================
REM revertir_butanoRendemento.bat – Desfacendo a túa tentativa de "optimización"
REM 
REM Reverte os cambios feitos por butanoRendemento.bat e devolve o PC
REM ao seu estado "seguro" antes de que alguén se decate da túa liada.
REM 
REM (Sí, necesitas permisos de admin, non sexas paquete)
REM ============================================================

set backupFile=%~dp0GamingPerfBackup.json

if not exist "%backupFile%" (
    echo [❌] ERROR: O ficheiro de backup %backupFile% non apareceu. 
    echo 🔍 Igual o devorou o lag? Pois agora toca improvisar...
    pause
    goto :EOF
)

echo ====================================================
echo [⏪] REVERTENDO AS TÚAS "MELHORAS" GAMER...
echo ====================================================

REM ---- Ler o ficheiro de backup e restaurar as variables ----
for /f "usebackq tokens=1* delims==" %%K in ("%backupFile%") do (
    set "key=%%K"
    set "value=%%L"
    if /i "%%K"=="PowerPlan" (
        set "restorePower=%%L"
    ) else if /i "%%K"=="Service_SysMain" (
        set "svcSys=%%L"
    ) else if /i "%%K"=="Service_DiagTrack" (
        set "svcDiag=%%L"
    ) else if /i "%%K"=="Service_WSearch" (
        set "svcWSearch=%%L"
    ) else if /i "%%K"=="Reg_VisualFXSetting" (
        set "regVisual=%%L"
    ) else if /i "%%K"=="Reg_MinAnimate" (
        set "regMinAnimate=%%L"
    ) else if /i "%%K"=="Reg_EnableTransparency" (
        set "regTrans=%%L"
    ) else if /i "%%K"=="Reg_HwSchMode" (
        set "regHwSch=%%L"
    )
)

REM ---- 1. Restaurar o plan de enerxía ----
if defined restorePower (
    powercfg /setactive %restorePower%
    echo 🔋 Plan de enerxía restaurado a %restorePower%. Xa podes volver ser ecolóxico.
) else (
    echo [⚠️] AVISO: Non atopei un backup do plan de enerxía. Quizais agora vas en modo vela.
)

REM ---- 2. Restaurar os servizos de Windows ----
call :RestoreService SysMain %svcSys%
call :RestoreService DiagTrack %svcDiag%
call :RestoreService WSearch %svcWSearch%

REM ---- 3. Restaurar valores do rexistro ----
if defined regVisual (
    if "%regVisual%"=="" (
        reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /f >nul
        echo 🎨 VisualFXSetting eliminado. Volve a túa "experiencia completa" de Windows.
    ) else (
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d %regVisual% /f >nul
        echo 🎨 VisualFXSetting restaurado a %regVisual%. De volta ao drama visual.
    )
)
if defined regMinAnimate (
    if "%regMinAnimate%"=="" (
        reg delete "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /f >nul
        echo 🏃 Animacións activadas de novo. O PC volve ser máis "cinemático".
    ) else (
        reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d %regMinAnimate% /f >nul
        echo 🏃 MinAnimate restaurado a %regMinAnimate%. Agora os menús xa non parecen teletransporte.
    )
)
if defined regTrans (
    if "%regTrans%"=="" (
        reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /f >nul
        echo 🔄 Transparencias de novo activadas. Xa podes ver a través das ventás.
    ) else (
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d %regTrans% /f >nul
        echo 🔄 EnableTransparency restaurado a %regTrans%. Xa non parece que o PC vaia explotar.
    )
)
if defined regHwSch (
    if "%regHwSch%"=="" (
        reg delete "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /f >nul
        echo 🎮 HwSchMode eliminado. Agora a GPU decide o que quere facer coa súa vida.
    ) else (
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d %regHwSch% /f >nul
        echo 🎮 HwSchMode restaurado a %regHwSch%. A ver se agora non petan os xogos.
    )
)

echo.
echo 🔄 Todos os cambios revertidos. Xa podes finxir que nunca tocaches nada.
echo 🔄 Recoméndase reiniciar o PC para que Windows non se dea conta.
pause
goto :EOF

:RestoreService
REM %1 = nome do servizo, %2 = backup en formato "startup|status"
for /f "tokens=1,2 delims=|" %%A in ("%2%") do (
    set "stype=%%A"
    set "sstatus=%%B"
)
sc config %1% start= %stype% >nul
if /I "%sstatus%"=="RUNNING" (
    net start %1% >nul 2>&1
    echo 🔄 Servizo %1% restaurado e iniciado en modo %stype%.
) else (
    net stop %1% >nul 2>&1
    echo 🔄 Servizo %1% restaurado pero apagado. Se Windows o necesita, xa chorará.
)
goto :EOF
