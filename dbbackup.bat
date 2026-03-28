@echo off
setlocal EnableDelayedExpansion

REM ===== CONFIG =====
set SOURCE=C:\Program Files (x86)\MultiSIBControl
set TEMP=C:\backup_msib_temp
set REMOTE=backupdb:backup_msibc_auto
set PUSHKEY=KEY
set PUSHDEVICE=DEVICE
set LOGDIR=C:\backup_logs

mkdir "%TEMP%" 2>nul
mkdir "%LOGDIR%" 2>nul

REM ===== FECHA =====
for /f "tokens=1-4 delims=/ " %%a in ("%date%") do set DATESTAMP=%%d%%b%%c
for /f "tokens=1-2 delims=: " %%a in ("%time%") do set TIMESTAMP=%%a%%b

set BACKUPNAME=msib_backup_%DATESTAMP%_%TIMESTAMP%
set LOGFILE=%LOGDIR%\backup_%DATESTAMP%_%TIMESTAMP%.log

echo ============================== > "%LOGFILE%"
echo INICIO BACKUP %DATESTAMP% %TIMESTAMP% >> "%LOGFILE%"
echo ============================== >> "%LOGFILE%"

echo Limpiando temporales... >> "%LOGFILE%"
del /q "%TEMP%\*.db3" >> "%LOGFILE%" 2>&1

echo Copiando archivos .db3... >> "%LOGFILE%"
robocopy "%SOURCE%" "%TEMP%" *.db3 /R:2 /W:2 >> "%LOGFILE%" 2>&1

echo Archivos en TEMP antes de comprimir: >> "%LOGFILE%"
dir "%TEMP%\*.db3" >> "%LOGFILE%" 2>&1

echo Comprimiendo... >> "%LOGFILE%"
cd /d "%TEMP%"

"C:\Program Files\7-Zip\7z.exe" a "%TEMP%\%BACKUPNAME%.7z" *.db3 >> "%LOGFILE%" 2>&1
    if not exist "%TEMP%\%BACKUPNAME%.7z" (
    echo ERROR EN COMPRESION >> "%LOGFILE%"
    curl "https://www.pushsafer.com/api?k=%PUSHKEY%&d=%PUSHDEVICE%&c=%23ff0000&t=MSIB&m=Backup%20FAILED%20-%20Compression"
    pause
    exit
)

echo Subiendo a Drive... >> "%LOGFILE%"
"C:\Users\Gea-minipc\Desktop\rclone\rclone.exe" copy "%TEMP%\%BACKUPNAME%.7z" %REMOTE% --retries 3 >> "%LOGFILE%" 2>&1

if %ERRORLEVEL% NEQ 0 (
    echo ERROR EN SUBIDA >> "%LOGFILE%"
    curl "https://www.pushsafer.com/api?k=%PUSHKEY%&d=%PUSHDEVICE%&c=%23ff0000&t=MSIB&m=Backup%20FAILED%20-%20Upload"
    pause
    exit
)

echo Manteniendo solo 2 backups... >> "%LOGFILE%"
"C:\Users\Gea-minipc\Desktop\rclone\rclone.exe" lsf %REMOTE% --format "tp" --separator ";" > "%TEMP%\list.txt"
for /f "skip=2 tokens=1 delims=;" %%A in ("%TEMP%\list.txt") do (
    "C:\Users\Gea-minipc\Desktop\rclone\rclone.exe" delete "%REMOTE%/%%A" >> "%LOGFILE%" 2>&1
)

del /q "%TEMP%\*.db3"
del /q "%TEMP%\*.7z"
del /q "%TEMP%\list.txt"

echo BACKUP FINALIZADO OK >> "%LOGFILE%"

curl "https://www.pushsafer.com/api?k=%PUSHKEY%&d=%PUSHDEVICE%&c=%2300cc00&t=MSIB&m=Backup%20OK"
