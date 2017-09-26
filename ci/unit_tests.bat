@echo off
setlocal enabledelayedexpansion

if "%WORKSPACE%" == "" (
  echo Error: environment variable WORKSPACE must be defined. Aborting..
  exit /B 1
)

:: see if %WORKSPACE% is alread mapped to a drive
for /f "tokens=1* delims==> " %%G IN ('subst') do (
  set sdrive=%%G
  :: removing extra space
  set sdrive=!sdrive:~0,2!
  set spath=%%H

  if /I "!spath!" == "%WORKSPACE%" (
    set use_drive=!sdrive!
    goto :found_drive
  )
)

:: no existing mapping
:: try to assign "%WORKSPACE%" to the first drive letter which works
for %%i in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
    set "drive=%%i:"
    subst !drive! "%WORKSPACE%" >nul
    if not errorlevel 1 (
        set use_drive=!drive!
        goto :found_drive
    )
)

echo Error: unable to subst drive to path %WORKSPACE%. Aborting...
exit /B 1

:found_drive
echo Using drive !use_drive! for %WORKSPACE%

:: change current directory to that drive
!use_drive!

:: Since we are using the system jruby, we need to make sure our jvm process
:: uses at least 1g of memory, If we don't do this we can get OOM issues when
:: installing gems. See https://github.com/elastic/logstash/issues/5179

set JRUBY_OPTS="-J-Xmx1g"
set SELECTEDTESTSUITE=%1
set /p JRUBYVERSION=<.ruby-version

if "%JRUBYSRCDIR%" == "" (
  echo Error: environment variable JRUBYSRCDIR must be defined. Aborting..
  exit /B 1
)

if not exist %JRUBYSRCDIR% (
  echo Error: variable JRUBYSRCDIR must be declared with a valid directory. Aborting..
  exit /B 1
)

set JRUBYPATH=%JRUBYSRCDIR%\%JRUBYVERSION%

if not exist %JRUBYPATH% (
  echo Error: could not find JRuby in %JRUBYPATH%. Aborting..
  exit /B 1
)

set RAKEPATH=%JRUBYPATH%\bin\rake

echo Installing core plugins..
call %RAKEPATH% test:install-core
if errorlevel 1 (
  echo Error: failed to install core plugins. Aborting..
  exit /B 1
)

if "%SELECTEDTESTSUITE%" == "core-fail-fast" (
  echo Running core-fail-fast tests..
  call %RAKEPATH% test:core-fail-fast
) else (
  echo Running core tests..
  call %RAKEPATH% test:core
)
if errorlevel 1 (
  echo Error: failed to run core tests. Aborting..
  exit /B 1
)
