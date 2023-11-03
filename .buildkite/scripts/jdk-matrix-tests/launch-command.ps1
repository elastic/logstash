# ********************************************************
# This file contains prerequisite bootstrap invocations
# required for Logstash CI JDK matrix tests
# ********************************************************

$ErrorActionPreference = "Stop"

param (
    [string]$JDK,
    [switch]$OS,
    [string]$CIScript,
    [switch]$TestNameHuman,
    [switch]$TestNameSlug
)

# unset generic JAVA_HOME
if (Test-Path env:THEENVAR) {
    Remove-Item -Path env:JAVA_HOME
    Write-Host "--- Environment variable 'JAVA_HOME' has been unset."
} else {
    Write-Host "--- Environment variable 'JAVA_HOME' doesn't exist. Continuing."
}

# LS env vars for JDK matrix tests
$JAVA_CUSTOM_DIR = "C:\buildkite-agent\.java\$JDK"
$env:BUILD_JAVA_HOME = $JAVA_CUSTOM_DIR
$env:RUNTIME_JAVA_HOME = $JAVA_CUSTOM_DIR
$env:LS_JAVA_HOME = $JAVA_CUSTOM_DIR

buildkite-agent annotate ":bk-status-running: **$TestNameHuman** / **$OS** / **$JDK**" --context=windows-$TestNameSlug-$OS-$JDK
& $CIScript
buildkite-agent annotate ":bk-status-passed: **$TestNameHuman** / **$OS** / **$JDK**" --context=windows-$TestNameSlug-$OS-$JDK
