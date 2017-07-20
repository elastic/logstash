@echo off

setlocal

REM Since we are using the system jruby, we need to make sure our jvm process
REM uses at least 1g of memory, If we don't do this we can get OOM issues when
REM installing gems. See https://github.com/elastic/logstash/issues/5179

SET JRUBY_OPTS="-J-Xmx1g"
SET SELECTEDTESTSUITE=%1
SET /p JRUBYVERSION=<.ruby-version

IF NOT EXIST %JRUBYSRCDIR% (
  echo "Variable JRUBYSRCDIR must be declared with a valid directory. Aborting.."
  exit /B 1
)

SET JRUBYPATH=%JRUBYSRCDIR%\%JRUBYVERSION%

IF NOT EXIST %JRUBYPATH% (
  echo "Could not find JRuby in %JRUBYPATH%. Aborting.."
  exit /B 1
)

SET RAKEPATH=%JRUBYPATH%\bin\rake

IF "%SELECTEDTESTSUITE%"=="core-fail-fast" (
  echo "Running core-fail-fast tests"
  %RAKEPATH% test:install-core
REM ensure that a rake failure will cause the test to fail
  if %errorlevel% neq 0 exit /b %errorlevel%
  %RAKEPATH% test:core-fail-fast
  if %errorlevel% neq 0 exit /b %errorlevel%
) ELSE (
  IF "%SELECTEDTESTSUITE%"=="all" (
    echo "Running all plugins tests"
    %RAKEPATH% test:install-all
    if %errorlevel% neq 0 exit /b %errorlevel%
    %RAKEPATH% test:plugins
    if %errorlevel% neq 0 exit /b %errorlevel%
  ) ELSE (
    echo "Running core tests"
    %RAKEPATH% test:install-core
    if %errorlevel% neq 0 exit /b %errorlevel%
    %RAKEPATH% test:core
    if %errorlevel% neq 0 exit /b %errorlevel%
  )
)
