@echo off
SETLOCAL

set SCRIPT_DIR=%~dp0
CALL %SCRIPT_DIR%\logstash.bat plugin %*
