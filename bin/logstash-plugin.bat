@echo off

SETLOCAL

set SCRIPT_DIR=%~dp0
CALL "%SCRIPT_DIR%\setup.bat"

:EXEC
if "%VENDORED_JRUBY%" == "" (
  %RUBYCMD% "%LS_HOME%\lib\pluginmanager\main.rb" %*
) else (
  %JRUBY_BIN% %jruby_opts% "%LS_HOME%\lib\pluginmanager\main.rb" %*
)

ENDLOCAL
