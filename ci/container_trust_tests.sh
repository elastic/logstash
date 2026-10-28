#!/bin/bash
# Checks the trust stores of the published Logstash images of LS_VERSION for this host's architecture
# (default: the snapshot of this branch's release track).
set -euo pipefail

LS_VERSION="${LS_VERSION:-$(./gradlew -q printStackVersion)}"
REGISTRY="${REGISTRY:-docker.elastic.co/logstash}"
JAVA="${JAVA_HOME:+${JAVA_HOME}/bin/}java"
QA_DIR="${PWD}/qa/bundled_jdk"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

failed=()
for image in logstash logstash-oss logstash-wolfi; do
  ref="${REGISTRY}/${image}:${LS_VERSION}"
  echo "--- ${ref}"
  [[ "${PULL:-true}" == "true" ]] && docker pull -q "${ref}" > /dev/null
  docker run --rm -v "${QA_DIR}:/qa:ro" --entrypoint /usr/share/logstash/bin/ruby "${ref}" \
    /qa/container_trust_check.rb /qa/fixtures 2>&1 | grep -v '^Using bundled JDK' || failed+=("${ref}")
done

# FIPS image: Java trusts its BCFKS store
ref="${REGISTRY}/logstash-observability-sre:${LS_VERSION}"
echo "--- ${ref}"
[[ "${PULL:-true}" == "true" ]] && docker pull -q "${ref}" > /dev/null
container="$(docker create "${ref}")"
docker cp -L "${container}:/usr/share/logstash/config/security/cacerts.bcfks" "${WORK_DIR}/cacerts.bcfks"
docker cp -L "${container}:/usr/share/logstash/logstash-core/lib/jars" "${WORK_DIR}/jars"
docker rm "${container}" > /dev/null
bc_fips_jar="$(find "${WORK_DIR}/jars" -name 'bc-fips-*.jar' | head -1)"
"${JAVA}" -cp "${bc_fips_jar}" "${QA_DIR}/BundledJdkTrustCheck.java" bcfks "${WORK_DIR}/cacerts.bcfks" "${QA_DIR}/fixtures" \
  || failed+=("${ref}")

if (( ${#failed[@]} )); then
  echo "+++ ${#failed[@]} checks failed:"
  printf '  %s\n' "${failed[@]}"
  exit 1
fi
echo "+++ all images passed"
