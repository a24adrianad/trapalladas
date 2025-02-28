@echo off
setlocal EnableDelayedExpansion
REM ============================================================
REM butanoPing.bat - O único script que realmente che fai voar o internet*
REM (* Non literalmente, pero mellor que ter a avoa coando o WiFi)
REM Uso:
REM   Para aplicar os hacks:
REM       butanoPing.bat
REM   Para revertelo todo cando veña IT a preguntar:
REM       butanoPing.bat revert
REM (Evidentemente, tes que executalo como administrador, máquina)
REM NON SEXAS BURRO, NON O EXECUTES DÚAS VECES SEGUIDAS
REM ============================================================

REM Aquí gardamos os backups por se rompes algo e logo choras
set REG_BACKUP=NetworkPingBackup.reg
set TCP_GLOBALS_BACKUP=TcpGlobalsBackup.txt
set SERVICE_BACKUP=ServiceBackup.txt
set ADAPTERS_BACKUP=ActiveAdaptersBackup.txt

REM Lista de servizos molestos que imos desactivar porque só consumen RAM e paciencia
set SERVICES=wuauserv BITS SysMain DiagTrack XblAuthManager XblGameSave XboxNetApiSvc

if /I "%1"=="revert" goto revert

echo ====================================================
echo [*] FACENDO BACKUP POR SE LOGO VEÑA A LIADA...
echo ====================================================

REM 1. Gardar claves de rexistro (para cando queiras finxir que non tocaches nada)
reg export "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" "%REG_BACKUP%" /y >nul
if errorlevel 1 (
    echo [!] ERROR: Non puiden gardar as claves. Seguro que tes permisos?
) else (
    echo [OK] Backup de claves feito. Gardado en %REG_BACKUP%. Non o perdas.
)

REM 2. Backup da configuración TCP por se o ping baixa tanto que o perdes de vista
netsh int tcp show global > "%TCP_GLOBALS_BACKUP%"
netsh int tcp show supplemental > nul
echo [OK] Backup da config TCP gardado en %TCP_GLOBALS_BACKUP%.

REM 3. Gardar o estado dos servizos molestos antes de desactivalos sen piedade
if exist "%SERVICE_BACKUP%" del "%SERVICE_BACKUP%"
for %%S in (%SERVICES%) do (
    for /f "tokens=2 delims=:" %%A in ('sc qc %%S ^| findstr /C:"START_TYPE"') do (
        set stype=%%A
        set stype=!stype: =!
        echo %%S=!stype!>> "%SERVICE_BACKUP%"
    )
)
echo [OK] Servizos molestos anotados. Gardado en %SERVICE_BACKUP%.

REM 4. Anotar os adaptadores de rede activos antes de tocalos
if exist "%ADAPTERS_BACKUP%" del "%ADAPTERS_BACKUP%"
for /f "tokens=2 delims==" %%A in ('wmic nic where "NetEnabled=true" get Name /value ^| find "Name="') do (
    echo %%A>> "%ADAPTERS_BACKUP%"
)
echo [OK] Adaptadores de rede anotados en %ADAPTERS_BACKUP%.

echo.
echo ====================================================
echo [*] HORA DE DOPAR A REDE COMO SE FORA CICLISMO NOS 90
echo ====================================================

REM A) Desactivar o algoritmo de Nagle, porque queremos internet rápido, non un fax
for /f "skip=1 tokens=*" %%I in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"') do (
    reg add "%%I" /v TcpAckFrequency /t REG_DWORD /d 1 /f >nul
    reg add "%%I" /v TCPNoDelay /t REG_DWORD /d 1 /f >nul
)
echo [OK] Nagle's Algorithm desactivado. Internet agora vai turbo.

REM B) Purgar DNS e resetear todo, porque non imos aceptar lag
ipconfig /flushdns >nul
netsh winsock reset >nul
netsh int ip reset >nul
echo [OK] DNS limpa, Winsock e TCP/IP reiniciados. Agora xa non tes escusa.

REM C) Axustes TCP para que o teu PC se volva un depredador do internet
netsh int tcp set global autotuninglevel=disabled >nul
netsh int tcp set global ecncapability=enabled >nul
netsh int tcp set global dca=enabled >nul
netsh int tcp set global netdma=enabled >nul
netsh int tcp set supplemental template=internet congestionprovider=ctcp >nul
echo [OK] Configuración TCP tunéada. Agora vai como un Fórmula 1.

REM D) Apagar servizos inútiles porque xa temos suficiente con pagar a luz
for %%S in (%SERVICES%) do (
    sc config %%S start= disabled >nul
    net stop %%S >nul 2>&1
)
echo [OK] Servizos irrelevantes apagados. Windows xa non te espía (tanto).

REM E) Reiniciar os adaptadores de rede, porque os queremos limpos e fresquiños
if exist "%ADAPTERS_BACKUP%" (
    for /f "usebackq delims=" %%A in ("%ADAPTERS_BACKUP%") do (
        echo Reiniciando "%%A"...
        netsh interface set interface name="%%A" admin=disabled >nul
        timeout /t 3 /nobreak >nul
        netsh interface set interface name="%%A" admin=enabled >nul
    )
    echo [OK] Adaptadores de rede reiniciados.
) else (
    echo [!] AVISO: Non atopei o backup dos adaptadores. Será cousa túa.
)

echo.
echo [!] Melloras aplicadas con éxito. Se non notas cambios, mala sorte.
echo [!] Recoméndase reiniciar o PC para que todo vaia fino fino.
pause
goto end

:revert
echo ====================================================
echo [*] REVERTENDO OS CAMBIOS, NON SE DIGA MÁIS...
echo ====================================================

REM 1. Restaurar claves de rexistro (para que non se note que tocaches algo)
if exist "%REG_BACKUP%" (
    reg import "%REG_BACKUP%" >nul
    echo [OK] Claves de rexistro restauradas dende %REG_BACKUP%.
) else (
    echo [!] ERROR: Arquivo de backup de rexistro non atopado.
)

REM 2. Restaurar configuración TCP estándar, porque ao parecer non che gusta a velocidade
netsh int tcp set global autotuninglevel=normal >nul
netsh int tcp set global ecncapability=enabled >nul
netsh int tcp set global dca=disabled >nul
netsh int tcp set global netdma=disabled >nul
netsh int tcp set supplemental template=internet congestionprovider=ctcp >nul
echo [OK] Configuración TCP restaurada aos valores estándar.

REM 3. Restaurar os tipos de inicio dos servizos dende o backup
if exist "%SERVICE_BACKUP%" (
    for /f "usebackq tokens=1,2 delims==" %%S in ("%SERVICE_BACKUP%") do (
        sc config %%S start= auto >nul
        net start %%S >nul 2>&1
    )
    echo [OK] Servizos restaurados.
) else (
    echo [!] ERROR: Non atopei o backup dos servizos. Mala túa.
)

REM 4. Reiniciar os adaptadores de rede
if exist "%ADAPTERS_BACKUP%" (
    for /f "usebackq delims=" %%A in ("%ADAPTERS_BACKUP%") do (
        echo Reiniciando "%%A"...
        netsh interface set interface name="%%A" admin=disabled >nul
        timeout /t 3 /nobreak >nul
        netsh interface set interface name="%%A" admin=enabled >nul
    )
    echo [OK] Adaptadores restaurados.
)

echo.
echo [*] Todo revertido. Xa podes finxir que nunca fixeches nada.
pause

:end
endlocal
