@echo off

set SCRIPT=%0

rem ### 1: determine logstash home

rem  to do this, we strip from the path until we
rem find bin, and then strip bin (there is an assumption here that there is no
rem nested directory under bin also named bin)

for %%I in (%SCRIPT%) do set LS_HOME=%%~dpI

:ls_home_loop
for %%I in ("%LS_HOME:~1,-1%") do set DIRNAME=%%~nxI
if not "%DIRNAME%" == "bin" (
  for %%I in ("%LS_HOME%..") do set LS_HOME=%%~dpfI
  goto ls_home_loop
)
for %%I in ("%LS_HOME%..") do set LS_HOME=%%~dpfI

rem ### 2: set java

if defined LS_JAVA_HOME (
  set JAVACMD=%LS_JAVA_HOME%\bin\java.exe
  echo Using LS_JAVA_HOME defined java: %LS_JAVA_HOME%
  if exist "%LS_HOME%\jdk" (
    echo WARNING: Using LS_JAVA_HOME while Logstash distribution comes with a bundled JDK.
  )
) else if defined JAVA_HOME (
  set JAVACMD="%JAVA_HOME%\bin\java.exe"
  echo Using JAVA_HOME defined java: %JAVA_HOME%
  if exist "%LS_HOME%\jdk" (
    echo WARNING: Using JAVA_HOME while Logstash distribution comes with a bundled JDK.
  )
  echo DEPRECATION: The use of JAVA_HOME is now deprecated and will be removed starting from 8.0. Please configure LS_JAVA_HOME instead.
) else (
  if exist "%LS_HOME%\jdk" (
    set JAVACMD=%LS_HOME%\jdk\bin\java.exe
    echo "Using bundled JDK: !JAVACMD!"
  ) else (
    for %%I in (java.exe) do set JAVACMD="%%~$PATH:I"
    echo "Using system java: !JAVACMD!"
  )
)

if not exist "%JAVACMD%" (
  echo could not find java; set JAVA_HOME or ensure java is in PATH 1>&2
  exit /b 1
)

rem do not let JAVA_TOOL_OPTIONS slip in (as the JVM does by default)
if not "%JAVA_TOOL_OPTIONS%" == "" (
  echo "warning: ignoring JAVA_TOOL_OPTIONS=$JAVA_TOOL_OPTIONS"
  set JAVA_TOOL_OPTIONS=
)

rem JAVA_OPTS is not a built-in JVM mechanism but some people think it is so we
rem warn them that we are not observing the value of %JAVA_OPTS%
if not "%JAVA_OPTS%" == "" (
  echo|set /p="warning: ignoring JAVA_OPTS=%JAVA_OPTS%; "
  echo pass JVM parameters via LS_JAVA_OPTS
)

rem ### 3: set jruby

set JRUBY_BIN="%LS_HOME%\vendor\jruby\bin\jruby"
if not exist %JRUBY_BIN% (
  echo "could not find jruby in %LS_HOME%\vendor\jruby" 1>&2
  exit /b 1
)

set RUBYLIB=%LS_HOME%\lib