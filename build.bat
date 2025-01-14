@echo off
setlocal enabledelayedexpansion

call :DownloadFileIfNotExists "redbean.exe" "https://redbean.dev/redbean-3.0.0.com"
call :DownloadFileIfNotExists "zip.exe" "https://cosmo.zip/pub/cosmos/bin/zip"

cp redbean.exe sharebean.exe
zip -r sharebean.exe ".init.lua" ".lua/" "app/"

echo Build success!
pause
exit /B 0

:DownloadFileIfNotExists
set "FILE_PATH=%~1"
set "FILE_URL=%~2"
if exist "%FILE_PATH%" (
    echo File exists: %FILE_PATH%
) else (
    echo File not exists, downloading...
    powershell -Command "Invoke-WebRequest -Uri %FILE_URL% -OutFile %FILE_PATH%"
    if exist "%FILE_PATH%" (
        echo Download success! %FILE_PATH%
    ) else (
        echo Download fail  %FILE_PATH%
    )
)
goto:eof


endlocal
