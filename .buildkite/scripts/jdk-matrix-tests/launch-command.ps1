# ********************************************************
# This file contains prerequisite bootstrap invocations
# required for Logstash CI JDK matrix tests
# ********************************************************

# expand previous command (shell invocation)
Write-Host "^^^ +++"

param (
    [string]$JDK,
    [string]$CIScript,
    [switch]$StepNameHuman,
    [switch]$AnnotateContext
)

# the unit test script expects the WORKSPACE env var
$env:WORKSPACE = $PWD.Path

# unset generic JAVA_HOME
if (Test-Path env:JAVA_HOME) {
    Remove-Item -Path env:JAVA_HOME
    Write-Host "--- Environment variable 'JAVA_HOME' has been unset."
} else {
    Write-Host "--- Environment variable 'JAVA_HOME' doesn't exist. Continuing."
}

# LS env vars for JDK matrix tests
$JAVA_CUSTOM_DIR = "C:\.java\$JDK"
$env:BUILD_JAVA_HOME = $JAVA_CUSTOM_DIR
$env:RUNTIME_JAVA_HOME = $JAVA_CUSTOM_DIR
$env:LS_JAVA_HOME = $JAVA_CUSTOM_DIR

Write-Host "--- Running tests"
Start-Process -FilePath $CIScript -Wait -NoNewWindow
if ($LASTEXITCODE -ne 0) {
    buildkite-agent annotate --context=$AnnotateContext --append "| :bk-status-failed: | $StepNameHuman |`n"
    Write-Host "^^^ +++"
    exit 1 
}
buildkite-agent annotate --context=$AnnotateContext --append "| :bk-status-passed: | $StepNameHuman |`n"
