@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0\.."
for /f %%i in ('cd') do set RESULT=%%i

"%JAVACMD%" -cp "!RESULT!\tools\ingest-converter\build\libs\ingest-converter.jar;*" ^
  org.logstash.ingest.Pipeline %*

endlocal
