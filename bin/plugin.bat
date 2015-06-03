@echo off

SETLOCAL

REM get logstash/bin absolute path: d => drive letter, p => path, s => use short names (no-spaces)
REM as explained on https://www.microsoft.com/resources/documentation/windows/xp/all/proddocs/en-us/percent.mspx?mfr=true
set SCRIPT_DIR=%~dps0
CALL %SCRIPT_DIR%\setup.bat

:EXEC
if "%VENDORED_JRUBY%" == "" (
  %RUBYCMD% "%LS_HOME%\lib\pluginmanager\main.rb" %*
) else (
  %JRUBY_BIN% %jruby_opts% "%LS_HOME%\lib\pluginmanager\main.rb" %*
)

ENDLOCAL
