@echo off

SETLOCAL

ECHO "The use of bin/plugin is deprecated and will be removed in a feature release. Please use bin/logstash-plugin."

set SCRIPT_DIR=%~dp0
CALL "%SCRIPT_DIR%\logstash-plugin.bat" %*
