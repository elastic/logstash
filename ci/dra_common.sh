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
    for image in logstash logstash-oss logstash-ubi8; do
        docker save "docker.elastic.co/logstash/${image}:${version}" | gzip -c > "build/${image}-${version}-docker-image-${arch}.tar.gz"
    done
}

function upload_to_bucket {
    local file="${1:?file required}"
    local version="${2:?stack-version required}"
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
