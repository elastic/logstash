@echo off

SETLOCAL

set SCRIPT_DIR=%~dp0
for %%I in ("%SCRIPT_DIR%..") do set LS_HOME=%%~dpfI

set URLSTUB=http://download.elasticsearch.org/logstash/logstash/

if not "%*" == "install contrib" (
  echo Usage: bin\plugin.bat install contrib
  goto finally
)

if not exist "%LS_HOME%\lib\logstash\version.rb" (
  echo "ERROR: Cannot determine Logstash version.  Exiting."
  goto finally
) else (
  for /F "tokens=3" %%a in ('findstr /B "LOGSTASH_VERSION" %LS_HOME%\lib\logstash\version.rb') do set "VERSION=%%a"  
)

set TARGETDIR=%LS_HOME%\vendor\logstash
if not exist "%TARGETDIR%" mkdir "%TARGETDIR%"

REM need to unquote VERSION string, strange syntax isn't it?
set FILENAME=logstash-contrib-%VERSION:"=%

set SUFFIX=.zip
set DOWNLOAD_URL=%URLSTUB%%FILENAME%%SUFFIX%
set TARGET=%TARGETDIR%\%FILENAME%%SUFFIX%

echo Downloading %DOWNLOAD_URL%... (may take a while, please be patient)
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "(New-Object System.Net.WebClient).DownloadFile('%DOWNLOAD_URL%', '%TARGET%')"

if not exist "%TARGET%" (
  echo "ERROR: Unable to download %DOWNLOAD_URL%"
  echo "Exiting."
  goto finally
) else (
  echo Finished download of %DOWNLOAD_URL%.
  echo Extracting archive into vendor\logstash
  PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& %LS_HOME%\bin\plugin-unzip.ps1 %TARGET% %TARGETDIR%"

  REM Copy contents to LS_HOME, adding on top of existing install
  echo Copying plugin content into %LS_HOME%...(again take a little while, please be patient)
  xcopy %TARGETDIR%\%FILENAME% %LS_HOME% /E /Y /Q
  echo Finished copying plugin content.
  goto finally
)

:finally

ENDLOCAL