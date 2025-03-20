#!/bin/bash
# get_test_half returns either the first or second half of integration tests
# Usage: get_test_half <half_number>
# half_number: 0 for first half, 1 for second half

half_number=$1
source ci/get-test-half.sh
specs=$(get_test_half "$half_number")
./gradlew --info --stacktrace -PfedrampHighMode=true runIntegrationTests -PrubyIntegrationSpecs="$specs"