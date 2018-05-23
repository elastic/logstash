#!/bin/bash -i
export GRADLE_OPTS="-Dorg.gradle.daemon=false -Dorg.gradle.logging.level=info"

./gradlew installDefaultGems 
bin/dependencies-report --csv report.csv
# We want this to show on the CI server
cat report.csv
