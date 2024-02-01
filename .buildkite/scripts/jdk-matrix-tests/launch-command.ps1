# ********************************************************
# This file contains prerequisite bootstrap invocations
# required for Logstash CI JDK matrix tests
# ********************************************************

param (
    [string]$JDK,
    [string]$CIScript,
    [string]$StepNameHuman,
    [string]$AnnotateContext,
    [switch]$Annotate
)

# expand previous buildkite folded section (command invocation)
Write-Host "^^^ +++"

# unset generic JAVA_HOME
if (Test-Path env:JAVA_HOME) {
    Remove-Item -Path env:JAVA_HOME
    Write-Host "--- Environment variable 'JAVA_HOME' has been unset."
} else {
    Write-Host "--- Environment variable 'JAVA_HOME' doesn't exist. Continuing."
}

# LS env vars for JDK matrix tests
$JAVA_CUSTOM_DIR = "C:\Users\buildkite\.java\$JDK"
$env:BUILD_JAVA_HOME = $JAVA_CUSTOM_DIR
$env:RUNTIME_JAVA_HOME = $JAVA_CUSTOM_DIR
$env:LS_JAVA_HOME = $JAVA_CUSTOM_DIR

Write-Host "--- Running test: $CIScript"
try {
    Invoke-Expression $CIScript

    if ($LASTEXITCODE -ne 0) {
        throw "Test script $CIScript failed with a non-zero code: $LASTEXITCODE"
    }

    if ($Annotate) {
        C:\buildkite-agent\bin\buildkite-agent.exe annotate --context="$AnnotateContext" --append "| :bk-status-passed: | $StepNameHuman |`n"
    }
} catch {
    # tests failed
    Write-Host "^^^ +++"
    if ($Annotate) {
        C:\buildkite-agent\bin\buildkite-agent.exe annotate --context="$AnnotateContext" --append "| :bk-status-failed: | $StepNameHuman |`n"
        Write-Host "--- Archiving test reports"
        & "7z.exe" a -r .\build_reports.zip .\logstash-core\build\reports\tests
    }
    exit 1
}
