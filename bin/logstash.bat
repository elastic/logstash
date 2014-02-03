@echo off

SETLOCAL

if not defined JAVA_HOME goto missing_java_home

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

set RUBYLIB=%LS_HOME%\lib
set GEM_HOME=%LS_HOME%\vendor\bundle\jruby\1.9\
set GEM_PATH=%GEM_HOME%

for %%I in ("%LS_HOME%\vendor\jar\jruby-complete-*.jar") do set JRUBY_JAR_FILE=%%I
if not defined JRUBY_JAR_FILE goto missing_jruby_jar

set RUBY_CMD="%JAVA_HOME%\bin\java" %JAVA_OPTS% %LS_JAVA_OPTS% -jar "%JRUBY_JAR_FILE%"

if "%*"=="deps" goto install_deps
goto run_logstash

:install_deps
if not exist "%LS_HOME%\logstash.gemspec" goto missing_gemspec
echo Installing gem dependencies. This will probably take a while the first time.
%RUBY_CMD% "%LS_HOME%\gembag.rb"
goto finally

:run_logstash
%RUBY_CMD% "%LS_HOME%\lib\logstash\runner.rb" %*
goto finally

:missing_java_home
echo JAVA_HOME environment variable must be set!
pause
goto finally

:missing_jruby_jar
md "%LS_HOME%\vendor\jar\"
echo Please download the JRuby Complete .jar from http://jruby.org/download to %LS_HOME%\vendor\jar\ and re-run this command.
pause
goto finally

:missing_gemspec
echo Cannot install dependencies; missing logstash.gemspec. This 'deps' command only works from a logstash git clone.
pause
goto finally

:finally

ENDLOCAL
