@echo off

SETLOCAL

if NOT DEFINED JAVA_HOME goto err

set SCRIPT_DIR=%~dp0
for %%I in ("%SCRIPT_DIR%..") do set LS_HOME=%%~dpfI


REM ***** JAVA options *****

if "%LS_MIN_MEM%" == "" (
set LS_MIN_MEM=256m
)

if "%LS_MAX_MEM%" == "" (
set LS_MAX_MEM=1g
)

set JAVA_OPTS=%JAVA_OPTS% -Xms%LS_MIN_MEM% -Xmx%LS_MAX_MEM%

REM Enable aggressive optimizations in the JVM
REM    - Disabled by default as it might cause the JVM to crash
REM set JAVA_OPTS=%JAVA_OPTS% -XX:+AggressiveOpts

set JAVA_OPTS=%JAVA_OPTS% -XX:+UseParNewGC
set JAVA_OPTS=%JAVA_OPTS% -XX:+UseConcMarkSweepGC
set JAVA_OPTS=%JAVA_OPTS% -XX:+CMSParallelRemarkEnabled
set JAVA_OPTS=%JAVA_OPTS% -XX:SurvivorRatio=8
set JAVA_OPTS=%JAVA_OPTS% -XX:MaxTenuringThreshold=1
set JAVA_OPTS=%JAVA_OPTS% -XX:CMSInitiatingOccupancyFraction=75
set JAVA_OPTS=%JAVA_OPTS% -XX:+UseCMSInitiatingOccupancyOnly

REM GC logging options -- uncomment to enable
REM JAVA_OPTS=%JAVA_OPTS% -XX:+PrintGCDetails
REM JAVA_OPTS=%JAVA_OPTS% -XX:+PrintGCTimeStamps
REM JAVA_OPTS=%JAVA_OPTS% -XX:+PrintClassHistogram
REM JAVA_OPTS=%JAVA_OPTS% -XX:+PrintTenuringDistribution
REM JAVA_OPTS=%JAVA_OPTS% -XX:+PrintGCApplicationStoppedTime
REM JAVA_OPTS=%JAVA_OPTS% -Xloggc:/var/log/logstash/gc.log

REM Causes the JVM to dump its heap on OutOfMemory.
set JAVA_OPTS=%JAVA_OPTS% -XX:+HeapDumpOnOutOfMemoryError
REM The path to the heap dump location, note directory must exists and have enough
REM space for a full heap dump.
REM JAVA_OPTS=%JAVA_OPTS% -XX:HeapDumpPath=$LS_HOME/logs/heapdump.hprof

SET RUBYLIB=%LS_HOME%\lib
SET GEM_HOME=%LS_HOME%\vendor\bundle\jruby\1.9\
SET GEM_PATH=%GEM_HOME%

"%JAVA_HOME%\bin\java" %JAVA_OPTS% %LS_JAVA_OPTS% -jar %LS_HOME%\vendor\jar\jruby-complete-%JRUBY_VERSION%.jar %LS_HOME%\lib\logstash\runner.rb %*
goto finally


:err
echo JAVA_HOME environment variable must be set!
pause


:finally

ENDLOCAL
