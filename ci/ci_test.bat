goto no_test
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
  %RAKEPATH% test:core-fail-fast
) ELSE (
  IF "%SELECTEDTESTSUITE%"=="all" (
    echo "Running all plugins tests"
    %RAKEPATH% test:install-all
    %RAKEPATH% test:plugins
  ) ELSE (
    echo "Running core tests"
    %RAKEPATH% test:install-core
    %RAKEPATH% test:core
  )
)
:no_test
echo ***** SKIPPING TESTS : https://github.com/elastic/logstash/issues/7634 *****
