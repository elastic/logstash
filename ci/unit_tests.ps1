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

$startingPath = Get-Location

## Map a drive letter to the current path to avoid path length issues

# First, check if there is already a mapping
$currentDir = $PWD.Path
$substOutput = subst

# Filter the subst output based on the path
$matchedLines = $substOutput | Where-Object { $_ -like "*$currentDir*" }

if ($matchedLines) {
    # $currentDir seems to be already mapped to another drive letter; switch to this drive
    # Extract the drive letter from the matched lines
    $driveLetter = $matchedLines | ForEach-Object {
        # Split the line by colon and extract the drive letter
        ($_ -split ':')[0]
    }
    $drivePath = "$driveLetter`:"

    Write-Output "$currentDir is already mapped to $drivePath."
    Set-Location -Path $drivePath
    Write-Output "Changing drive to $drivePath."
}
else {
    # $currentDir isn't mapped to a drive letter, let's find a free drive letter and change to it

    # Loop through drive letters A to Z; we don't use the 'A'..'Z' for BWC with Windows 2016 / Powershell < 7
    for ($driveLetterAscii = 65; $driveLetterAscii -le 90; $driveLetterAscii++) {
        $drivePath = [char]$driveLetterAscii + ":"

        # check if the drive letter is available
        if (-not (Test-Path $drivePath)) {
            # found a free drive letter, create the virtual drive mapping and switch to it
            subst $drivePath $currentDir

            Write-Output "Mapped $currentDir to $drivePath"
            Set-Location -Path $drivePath
            Write-Output "Changing drive to $drivePath."
            # exit the loop since we found a free drive letter
            break
        }
    }
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
        Write-Host "~~~ Running all tests via Gradle using $testOpts"
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

# switch back to the path when the script started
Set-Location -Path $startingPath
