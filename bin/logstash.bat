@echo off
setlocal enabledelayedexpansion
set params='%*'

call "%~dp0setup.bat" || exit /b 1
if errorlevel 1 (
	if not defined nopauseonerror (
		pause
	)
	exit /B %ERRORLEVEL%
)

rem iterate over the command line args and look for the argument
rem after --path.settings to see if the jvm.options file is in
rem that path and set LS_JVM_OPTIONS_CONFIG accordingly
:loop
for /F "usebackq tokens=1-2* delims= " %%A in (!params!) do (
    set current=%%A
    set next=%%B
    set params='%%B %%C'

    if "!current!" == "--path.settings" (
    	if exist !next!\jvm.options (
    	  set "LS_JVM_OPTIONS_CONFIG=!next!\jvm.options"
    	)
    )

    if not "x!params!" == "x" (
		goto loop
	)
)

rem if explicit jvm.options is not found use default location
if "%LS_JVM_OPTIONS_CONFIG%" == "" (
  set LS_JVM_OPTIONS_CONFIG="%LS_HOME%\config\jvm.options"
)

rem extract the options from the JVM options file %LS_JVM_OPTIONS_CONFIG%
rem such options are the lines beginning with '-', thus "findstr /b"
if exist %LS_JVM_OPTIONS_CONFIG% (
  for /F "usebackq delims=" %%a in (`findstr /b \- %LS_JVM_OPTIONS_CONFIG%`) do set options=!options! %%a
  set "LS_JAVA_OPTS=!options! %LS_JAVA_OPTS%"
) else (
  echo "warning: no jvm.options file found"
)
set JAVA_OPTS=%LS_JAVA_OPTS%

for %%i in ("%LS_HOME%\logstash-core\lib\jars\*.jar") do (
	call :concat "%%i"
)

%JAVA% %JAVA_OPTS% -cp %CLASSPATH% org.logstash.Logstash %*

endlocal

goto :eof
:concat
IF not defined CLASSPATH (
  set CLASSPATH="%~1"
) ELSE (
  set CLASSPATH=%CLASSPATH%;"%~1"
)
