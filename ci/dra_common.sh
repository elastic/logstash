function info {
    echo "INFO: $1"
}

function error {
    echo "ERROR: $1"
    exit 1
}

function save_docker_tarballs {
    local arch="${1:?architecture required}"
    local version="${2:?stack-version required}"
    local images="logstash logstash-oss"
    if [ "${arch}" != "aarch64" ]; then
        # No logstash-ubi8 for AARCH64
        images="logstash logstash-oss logstash-ubi8"
    fi

    for image in ${images}; do
        tar_file="${image}-${version}-docker-image-${arch}.tar"
        docker save -o "build/${tar_file}" \
            "docker.elastic.co/logstash/${image}:${version}" || \
            error "Unable to save tar file ${tar_file} for ${image} image."
        # NOTE: if docker save exited with non-zero the error log already exited the script
        gzip "build/${tar_file}"
    done
}

function upload_to_bucket {
    local file="${1:?file required}"
    local version="${2:?stack-version required}"
    info "Uploading ${file}..."
    gsutil cp "${file}" "gs://logstash-ci-artifacts/dra/${version}/"
}

# Since we are using the system jruby, we need to make sure our jvm process
# uses at least 1g of memory, If we don't do this we can get OOM issues when
# installing gems. See https://github.com/elastic/logstash/issues/5179
export JRUBY_OPTS="-J-Xmx1g"

# Extract the version number from the version.yml file
# e.g.: 8.6.0
# The suffix part like alpha1 etc is managed by the optional VERSION_QUALIFIER_OPT environment variable
STACK_VERSION=`cat versions.yml | sed -n 's/^logstash\:[[:space:]]\([[:digit:]]*\.[[:digit:]]*\.[[:digit:]]*\)$/\1/p'`

# ARCH is a Environment variable set in Jenkins
if [ -z "$ARCH" ]; then
	ARCH=aarch64
fi
