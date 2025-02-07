#!/bin/bash
# get_test_half returns either the first or second half of integration tests
# Usage: get_test_half <half_number>
# half_number: 0 for first half, 1 for second half

half_number=$1
docker build -t test-runner-image -f x-pack/distributions/internal/observabilitySRE/docker/Dockerfile .
docker run test-runner-image /bin/bash -c "
    source ci/get-test-half.sh
    specs=$(get_test_half $half_number)
    ./gradlew --info --stacktrace -PrunTestsInFIPSMode=true runIntegrationTests -PrubyIntegrationSpecs=\"\$specs\"
"