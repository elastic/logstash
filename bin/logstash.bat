@echo off

SETLOCAL

REM get logstash/bin absolute path: d => drive letter, p => path, s => use short names (no-spaces)
REM as explained on https://www.microsoft.com/resources/documentation/windows/xp/all/proddocs/en-us/percent.mspx?mfr=true
set SCRIPT_DIR=%~dps0
CALL %SCRIPT_DIR%\setup.bat

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
