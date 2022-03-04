@echo off
setlocal enabledelayedexpansion 

call "%~dp0setup.bat" || exit /b 1
if errorlevel 1 (
	if not defined nopauseonerror (
		pause
	)
	exit /B %ERRORLEVEL%
)


set JAVA_OPTS=%LS_JAVA_OPTS%

for %%i in ("%LS_HOME%\logstash-core\lib\jars\*.jar") do (
	call :concat "%%i"
)

%JAVA% %JAVA_OPTS% -cp "%CLASSPATH%" org.logstash.ackedqueue.PqRepair %*

:concat
IF not defined CLASSPATH (
  set CLASSPATH="%~1"
) ELSE (
  set CLASSPATH=%CLASSPATH%;"%~1"
)
goto :eof 

endlocal
