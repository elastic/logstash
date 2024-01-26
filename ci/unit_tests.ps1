<#
.SYNOPSIS
    This is a gradle wrapper script to help run the Logstash unit tests on Windows.

.PARAMETER UnnamedArgument1
    Optionally allows to specify a subset of tests.
    Allows values are "ruby" or "java".
    If unset, all tests are executed.

.EXAMPLE
    .\ci\unit_tests.ps1
    Runs all unit tests.

    .\ci\unit_tests.ps1 java
    Runs only Java unit tests.
#>

$selectedTestSuite="all"

if ($args.Count -eq 1) {
    $selectedTestSuite=$args[0]
}

if (Test-Path Env:BUILD_JAVA_HOME) {    
    if (Test-Path Env:GRADLE_OPTS) {    
        $env:GRADLE_OPTS=$env:GRADLE_OPTS + " " + "-Dorg.gradle.java.home=" + $env:BUILD_JAVA_HOME
    } else {
        $env:GRADLE_OPTS="-Dorg.gradle.java.home=" + $env:BUILD_JAVA_HOME
    }
}

$testOpts = "GRADLE_OPTS: $env:GRADLE_OPTS, BUILD_JAVA_HOME: $env:BUILD_JAVA_HOME"

try {
    if ($selectedTestSuite -eq "java") {
        Write-Host "~~~ :java: Running Java tests via Gradle using $testOpts"
        $CIScript = ".\gradlew.bat javaTests --console=plain --no-daemon --info"
        Invoke-Expression $CIScript
    }
    elseif ($selectedTestSuite -eq "ruby") {
        Write-Host "~~~ :ruby: Running Ruby tests via Gradle using $testOpts"
        $CIScript = ".\gradlew.bat rubyTests --console=plain --no-daemon --info"
        Invoke-Expression $CIScript
    }
    else {
        Write-Host "~~~ 🧪 Running all tests via Gradle using $testOpts"
        $CIScript = ".\gradlew.bat test --console=plain --no-daemon --info"
        Invoke-Expression $CIScript
    }

    if ($LASTEXITCODE -ne 0) {
        throw "Test script $CIScript failed with a non-zero code: $LASTEXITCODE"
    }
} catch {
    # tests failed
    Write-Host "^^^ +++"
    exit 1
}
