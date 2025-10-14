function info {
    echo "--- INFO: $1"
}

function error {
    echo "--- ERROR: $1"
    exit 1
}

function save_docker_tarballs {
    local arch="${1:?architecture required}"
    local version="${2:?stack-version required}"
    local images="logstash logstash-oss logstash-wolfi"

    for image in ${images}; do
        tar_file="${image}-${version}-docker-image-${arch}.tar"
        docker save -o "build/${tar_file}" \
            "docker.elastic.co/logstash/${image}:${version}" || \
            error "Unable to save tar file ${tar_file} for ${image} image."
        # NOTE: if docker save exited with non-zero the error log already exited the script
        gzip "build/${tar_file}"
    done
}

# normalized $ARCH should be either "amd64" or "arm64"
function normalize_arch {
    case "$ARCH" in
        x86_64|amd64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        *)
            error "Unsupported architecture: $ARCH"
            ;;
    esac
}

# Since we are using the system jruby, we need to make sure our jvm process
# uses at least 1g of memory, If we don't do this we can get OOM issues when
# installing gems. See https://github.com/elastic/logstash/issues/5179
export JRUBY_OPTS="-J-Xmx4g"

# Extract the version number from the version.yml file
# e.g.: 8.6.0
# The suffix part like alpha1 etc is managed by the optional VERSION_QUALIFIER environment variable
STACK_VERSION=`cat versions.yml | sed -n 's/^logstash\:[[:space:]]\([[:digit:]]*\.[[:digit:]]*\.[[:digit:]]*\)$/\1/p'`

info "Agent is running on architecture [$(uname -i)]"

export VERSION_QUALIFIER=${VERSION_QUALIFIER:-""}
export DRA_DRY_RUN=${DRA_DRY_RUN:-""}

if [[ ! -z $DRA_DRY_RUN && $BUILDKITE_STEP_KEY == "logstash_publish_dra" ]]; then
    info "Release manager will run in dry-run mode [$DRA_DRY_RUN]"
fi
