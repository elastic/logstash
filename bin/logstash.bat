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

if "%1" == "-V" goto version
if "%1" == "--version" goto version

rem iterate over the command line args and look for the argument
rem after --path.settings to see if the jvm.options file is in
rem that path and set LS_JVM_OPTS accordingly
:loop
for /F "usebackq tokens=1-2* delims= " %%A in (!params!) do (
    set current=%%A
    set next=%%B
    set params='%%B %%C'

    if "!current!" == "--path.settings" (
    	if exist !next!\jvm.options (
    	  set "LS_JVM_OPTS=!next!\jvm.options"
    	)
    )

    if not "x!params!" == "x" (
		goto loop
	)
)

for %%i in ("%LS_HOME%\logstash-core\lib\jars\*.jar") do (
	call :concat "%%i"
)

@setlocal
for /F "usebackq delims=" %%a in (`CALL "%JAVACMD%" -cp "!CLASSPATH!" "org.logstash.launchers.JvmOptionsParser" "!LS_HOME!" "!LS_JVM_OPTS!" ^|^| echo jvm_options_parser_failed`) do set LS_JAVA_OPTS=%%a
@endlocal & set "MAYBE_JVM_OPTIONS_PARSER_FAILED=%LS_JAVA_OPTS%" & set LS_JAVA_OPTS=%LS_JAVA_OPTS%

if "%MAYBE_JVM_OPTIONS_PARSER_FAILED%" == "jvm_options_parser_failed" (
  echo "error: jvm options parser failed; exiting"
  exit /b 1
)
set JAVA_OPTS=%LS_JAVA_OPTS%

"%JAVACMD%" %JAVA_OPTS% -cp "%CLASSPATH%" org.logstash.Logstash %*

goto :end

:version
set LOGSTASH_VERSION_FILE1="%LS_HOME%\logstash-core\versions-gem-copy.yml"
set LOGSTASH_VERSION_FILE2="%LS_HOME%\versions.yml"

set "LOGSTASH_VERSION=Version not detected"
if exist !LOGSTASH_VERSION_FILE1! (
	rem this file is present in zip, deb and rpm artifacts and after bundle install
	rem but might not be for a git checkout type install
	for /F "tokens=1,2 delims=: " %%a in ('type !LOGSTASH_VERSION_FILE1!') do (
		if "%%a"=="logstash" set LOGSTASH_VERSION=%%b
	)
) else (
	if exist !LOGSTASH_VERSION_FILE2! (
		rem this file is present for a git checkout type install
		rem but its not in zip, deb and rpm artifacts (and in integration tests)
		for /F "tokens=1,2 delims=: " %%a in ('type !LOGSTASH_VERSION_FILE2!') do (
			if "%%a"=="logstash" set LOGSTASH_VERSION=%%b
		)
	)
)
echo logstash !LOGSTASH_VERSION!
goto :end

:concat
IF not defined CLASSPATH (
  set CLASSPATH=%~1
) ELSE (
  set CLASSPATH=%CLASSPATH%;%~1
)
goto :eof

:end
endlocal
exit /B %ERRORLEVEL%
