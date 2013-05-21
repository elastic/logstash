#!/bin/bash

build_jar=build/jar
build_services=build/META-INF/services
build_monolith=${1}
shift

mkdir -p ${build_jar}

# echo "******$(pwd)"
# echo "******${build_monolith}"

# Unpack META-INF/services in jars into individual directories
for jar in $(find "$@" -name \*.jar)
do
    # echo "******${jar}"
    dir="${jar##*/}"
    mkdir -p "${build_jar}/${dir}"
    pushd "${build_jar}/${dir}" &>/dev/null
    jar xf "../../../${jar}" META-INF/services
    popd &>/dev/null
done

# Merge all files under META-INF/services in jars
mkdir -p ${build_services}
rm -f ${build_services}/*
for src in $(find ${build_jar} -type f)
do
    dest=${src##*/}
    if [ -e "${build_services}/${dest}" ]
    then
	cat "${src}" >> "${build_services}/${dest}"
    else
	cp "${src}" ${build_services}
    fi
done

cp -f ${build_services}/* ${build_monolith}/META-INF/services/
