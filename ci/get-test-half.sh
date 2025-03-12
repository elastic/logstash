#!/bin/bash

# get_test_half returns either the first or second half of integration tests
# Usage: get_test_half <half_number>
# half_number: 0 for first half, 1 for second half
get_test_half() {
    local half_number=$1
    # Ensure only spec files go to stdout
    pushd qa/integration >/dev/null 2>&1
    
    # Collect all spec files
    local glob1=(specs/*spec.rb)
    local glob2=(specs/**/*spec.rb)
    local all_specs=("${glob1[@]}" "${glob2[@]}")
    
    # Calculate the split point
    local split_point=$((${#all_specs[@]} / 2))
    
    # Get the requested half (:: is "up to", : is "from")
    if [[ $half_number -eq 0 ]]; then
        local specs="${all_specs[@]::$split_point}"
    else
        local specs="${all_specs[@]:$split_point}"
    fi
    popd >/dev/null 2>&1
    echo "$specs"
}