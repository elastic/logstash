@echo off

SETLOCAL

set SCRIPT_DIR=%~dp0
CALL "%SCRIPT_DIR%\setup.bat"

:EXEC
REM is the first argument a flag? If so, assume 'agent'
set first_arg=%1
setlocal EnableDelayedExpansion
if "!first_arg:~0,1!" equ "-" (
  if "%VENDORED_JRUBY%" == "" (
    %RUBYCMD% "%LS_HOME%\lib\bootstrap\environment.rb" "logstash\runner.rb" agent %*
  ) else (
    %JRUBY_BIN% %jruby_opts% "%LS_HOME%\lib\bootstrap\environment.rb" "logstash\runner.rb" agent %*
  )
) else (
  if "%VENDORED_JRUBY%" == "" (
    %RUBYCMD% "%LS_HOME%\lib\bootstrap\environment.rb" "logstash\runner.rb" %*
  ) else (
    %JRUBY_BIN% %jruby_opts% "%LS_HOME%\lib\bootstrap\environment.rb" "logstash\runner.rb" %*
  )
)

ENDLOCAL
