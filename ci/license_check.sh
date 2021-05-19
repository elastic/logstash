#!/bin/bash -i
export GRADLE_OPTS="-Xmx2g -Dorg.gradle.daemon=false -Dorg.gradle.logging.level=info -Dfile.encoding=UTF-8"

./gradlew installDefaultGems
bin/dependencies-report --csv report.csv

result=$?

# We want this to show on the CI server
cat report.csv

exit $result
