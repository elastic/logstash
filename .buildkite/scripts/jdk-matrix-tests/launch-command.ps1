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

Start-Sleep -Seconds 300

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
$JAVA_CUSTOM_DIR = "C:\Users\buildkite\.java\$JDK"
$env:BUILD_JAVA_HOME = $JAVA_CUSTOM_DIR
$env:RUNTIME_JAVA_HOME = $JAVA_CUSTOM_DIR
$env:LS_JAVA_HOME = $JAVA_CUSTOM_DIR

Write-Host "--- Running tests"
try {
    Start-Process -FilePath $CIScript -Wait -NoNewWindow
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
}
# if ($? -or ($LASTEXITCODE -ne $null -and $LASTEXITCODE -eq 0)) {
#     # success
#     if ($Annotate) {
#         C:\buildkite-agent\bin\buildkite-agent.exe annotate --context="$AnnotateContext" --append "| :bk-status-passed: | $StepNameHuman |`n"
#     }
# } else {
#     # tests failed
#     Write-Host "^^^ +++"
#     if ($Annotate) {
#         C:\buildkite-agent\bin\buildkite-agent.exe annotate --context="$AnnotateContext" --append "| :bk-status-failed: | $StepNameHuman |`n"
#         Write-Host "--- Archiving test reports"
#         & "7z.exe" a -r .\build_reports.zip .\logstash-core\build\reports\tests
#     }
#     exit 1
# }    
