@echo off
setlocal enabledelayedexpansion

if "%WORKSPACE%" == "" (
  echo Error: environment variable WORKSPACE must be defined
  exit /B 1
)

:: see if %WORKSPACE% is alread mapped to a drive
for /f "tokens=1* delims==> " %%G IN ('subst') do (
  set sdrive=%%G
  :: removing extra space
  set sdrive=!sdrive:~0,2!
  :: expanding H to a short path in order not to break the resulting command line
  set spath=%%~sfH

  rem echo trying !spath! vs "%WORKSPACE%"
  if /I "!spath!" == "%WORKSPACE%" (
    rem echo found drive=!sdrive!, path=!spath!
    set use_drive=!sdrive!
    goto :found_drive
  )
)

:: no existing mapping
:: try to assign "%WORKSPACE%" to the first drive letter which works
for %%i in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
    set "drive=%%i:"
    rem echo trying subst !drive! "%WORKSPACE%"
    subst !drive! "%WORKSPACE%" >nul
    if not errorlevel 1 (
        set use_drive=!drive!
        goto :found_drive
    )
)

echo Error: unable to subst drive to path "%WORKSPACE%"
exit /B 1

:found_drive
echo using drive !use_drive! for "%WORKSPACE%"

:: change current directory to that drive
!use_drive!

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
  echo "Running core tests"
  %RAKEPATH% test:install-core
  %RAKEPATH% test:core
)
