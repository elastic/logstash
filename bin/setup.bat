@echo off

for %%I in ("%SCRIPT_DIR%..") do set LS_HOME=%%~dpfI

if "%USE_RUBY%" == "1" (
goto setup_ruby
) else (
goto setup_jruby
)

:setup_ruby
set RUBYCMD=ruby
set VENDORED_JRUBY=
goto finally

:setup_jruby
REM setup_java()
IF NOT DEFINED JAVA_HOME (
  FOR %%I IN (java.exe) DO set JAVA_EXE=%%~$PATH:I
)
if defined JAVA_EXE set JAVA_HOME=%JAVA_EXE:\bin\java.exe=%
if defined JAVA_EXE echo Using JAVA_HOME=%JAVA_HOME% retrieved from PATH

if not defined JAVA_HOME goto missing_java_home
REM ***** JAVA options *****

if "%LS_HEAP_SIZE%" == "" (
    set LS_HEAP_SIZE=1g
)

IF NOT "%JAVA_OPTS%" == "" (
    ECHO JAVA_OPTS was set to [%JAVA_OPTS%]. Logstash will trust these options, and not set any defaults that it might usually set
    goto opts_defined
)

    SET JAVA_OPTS=%JAVA_OPTS% -Xmx%LS_HEAP_SIZE%

    REM Enable aggressive optimizations in the JVM
    REM    - Disabled by default as it might cause the JVM to crash
    REM set JAVA_OPTS=%JAVA_OPTS% -XX:+AggressiveOpts

    SET JAVA_OPTS=%JAVA_OPTS% -XX:+UseParNewGC
    SET JAVA_OPTS=%JAVA_OPTS% -XX:+UseConcMarkSweepGC
    SET JAVA_OPTS=%JAVA_OPTS% -XX:+CMSParallelRemarkEnabled
    SET JAVA_OPTS=%JAVA_OPTS% -XX:SurvivorRatio=8
    SET JAVA_OPTS=%JAVA_OPTS% -XX:MaxTenuringThreshold=1
    SET JAVA_OPTS=%JAVA_OPTS% -XX:CMSInitiatingOccupancyFraction=75
    SET JAVA_OPTS=%JAVA_OPTS% -XX:+UseCMSInitiatingOccupancyOnly

    REM GC logging options -- uncomment to enable
    REM JAVA_OPTS=%JAVA_OPTS% -XX:+PrintGCDetails
    REM JAVA_OPTS=%JAVA_OPTS% -XX:+PrintGCTimeStamps
    REM JAVA_OPTS=%JAVA_OPTS% -XX:+PrintClassHistogram
    REM JAVA_OPTS=%JAVA_OPTS% -XX:+PrintTenuringDistribution
    REM JAVA_OPTS=%JAVA_OPTS% -XX:+PrintGCApplicationStoppedTime
    REM JAVA_OPTS=%JAVA_OPTS% -Xloggc:/var/log/logstash/gc.log

    REM Causes the JVM to dump its heap on OutOfMemory.
    SET JAVA_OPTS=%JAVA_OPTS% -XX:+HeapDumpOnOutOfMemoryError
    REM The path to the heap dump location, note directory must exists and have enough
    REM space for a full heap dump.
    SET JAVA_OPTS=%JAVA_OPTS% -XX:HeapDumpPath="%LS_HOME%/heapdump.hprof"
:opts_defined


IF NOT "%LS_JAVA_OPTS%" == "" (
    ECHO LS_JAVA_OPTS was set to [%LS_JAVA_OPTS%]. This will be appended to the JAVA_OPTS [%JAVA_OPTS%]
    SET JAVA_OPTS=%JAVA_OPTS% %LS_JAVA_OPTS%
)

REM setup_vendored_jruby()
set JRUBY_BIN="%LS_HOME%\vendor\jruby\bin\jruby"
if exist "%JRUBY_BIN%" (
  set VENDORED_JRUBY=1
goto finally
) else (
goto missing_jruby
)

:missing_java_home
echo JAVA_HOME environment variable must be set!
exit /b
echo Done

:missing_jruby
echo Unable to find JRuby.
echo If you are a user, this is a bug.
echo If you are a developer, please run 'rake bootstrap'. Running 'rake' requires the 'ruby' program be available.
exit /b

:finally

set RUBYLIB=%LS_HOME%\lib
