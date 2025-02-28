@echo off
setlocal EnableDelayedExpansion
REM ============================================================
REM revertir_butanoPing.bat – Botón do pánico para desfacer a liada
REM Reverte os cambios de butanoPing.bat e fai que pareza que nunca tocaches nada.
REM (Evidentemente, tes que executalo como administrador, non sexas paquete)
REM ============================================================

REM Definir nomes dos ficheiros de backup (se non os tes, mala túa)
set REG_BACKUP=NetworkPingBackup.reg
set SERVICE_BACKUP=ServiceBackup.txt
set ADAPTERS_BACKUP=ActiveAdaptersBackup.txt

echo ====================================================
echo [⏪] REVERTENDO A TÚA REDE PARA QUE NON CHORE O WINDOWS...
echo ====================================================

REM 1. Restaurar claves de rexistro (para que non se note que fixeches nada)
if exist "%REG_BACKUP%" (
    reg import "%REG_BACKUP%" >nul
    if %ERRORLEVEL% equ 0 (
        echo ✅ Claves de rexistro restauradas dende %REG_BACKUP%. Agora non deixas rastro.
    ) else (
        echo [❌] ERROR: Non puiden importar o backup de rexistro. Alguén meteu man?
    )
) else (
    echo [⚠️] AVISO: O backup do rexistro non apareceu. Igual xa era tarde para salvar isto.
)

REM 2. Restaurar os axustes TCP de fábrica, por se Windows estaba a gusto no modo tortuga
echo 🔄 Restaurando configuración TCP de Windows...
netsh int tcp set global autotuninglevel=normal >nul
netsh int tcp set global ecncapability=enabled >nul
netsh int tcp set global dca=disabled >nul
netsh int tcp set global netdma=disabled >nul
netsh int tcp set supplemental template=internet congestionprovider=ctcp >nul
netsh int tcp set global chimney=automatic >nul
netsh int tcp set global rss=enabled >nul
echo ✅ Axustes TCP restaurados. Agora volve ser o Windows de sempre... para ben ou para mal.

REM 3. Restaurar o estado dos servizos antes de que pensaras que sabías máis ca Microsoft
if exist "%SERVICE_BACKUP%" (
    for /f "usebackq tokens=1,2 delims==" %%S in ("%SERVICE_BACKUP%") do (
        set service=%%S
        set stype=%%T
        REM Convertir números en palabras para que Windows non se confunda
        if "!stype!"=="2" (
            set keyword=auto
        ) else if "!stype!"=="3" (
            set keyword=demand
        ) else if "!stype!"=="4" (
            set keyword=disabled
        ) else (
            set keyword=auto
        )
        echo 🔄 Restaurando servizo !service! ao estado: !keyword!...
        sc config !service! start= !keyword! >nul
        if /I "!keyword!"=="auto" (
            net start !service! >nul 2>&1
        )
    )
    echo ✅ Estado dos servizos restaurado. Agora Windows volve estar vixiado.
) else (
    echo [⚠️] AVISO: O backup dos servizos desapareceu. Igual xa non había moito que restaurar.
)

REM 4. Reiniciar os adaptadores de rede, porque así parece que fixeches algo técnico
if exist "%ADAPTERS_BACKUP%" (
    for /f "usebackq delims=" %%A in ("%ADAPTERS_BACKUP%") do (
        echo 🔄 Reiniciando adaptador de rede "%%A"... 
        netsh interface set interface name="%%A" admin=disabled >nul
        timeout /t 3 /nobreak >nul
        netsh interface set interface name="%%A" admin=enabled >nul
    )
    echo ✅ Adaptadores de rede reiniciados. Xa podes dicir que "reiniciaste a rede".
) else (
    echo [⚠️] AVISO: Non atopei o backup dos adaptadores de rede. Seguro que o fixeches ben?
)

echo.
echo ✅ Configuración de rede revertida con éxito. Agora semella que nunca tocaches nada.
echo 🔄 Recoméndase reiniciar o PC para que os cambios teñan efecto e que non quede nada sospeitoso.
pause
endlocal
