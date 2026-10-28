#!/bin/bash
# Checks the trust store of the JDK bundled in each published artifact of LS_VERSION
# (default: the snapshot of this branch's release track).
set -euo pipefail

LS_VERSION="${LS_VERSION:-$(./gradlew -q printStackVersion)}"
if [[ "${LS_VERSION}" == *-SNAPSHOT ]]; then
  BASE_URL="${BASE_URL:-https://snapshots.elastic.co/downloads/logstash}"
else
  BASE_URL="${BASE_URL:-https://artifacts.elastic.co/downloads/logstash}"
fi
JAVA="${JAVA_HOME:+${JAVA_HOME}/bin/}java"
QA_DIR="${PWD}/qa/bundled_jdk"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

for tool in curl tar unzip dpkg-deb rpm2cpio cpio; do
  command -v "${tool}" > /dev/null || { echo "missing ${tool}"; exit 1; }
done

failed=()
for flavor in logstash logstash-oss; do
  for suffix in linux-x86_64.tar.gz linux-aarch64.tar.gz darwin-x86_64.tar.gz darwin-aarch64.tar.gz \
                windows-x86_64.zip amd64.deb arm64.deb x86_64.rpm aarch64.rpm; do
    artifact="${flavor}-${LS_VERSION}-${suffix}"
    echo "--- ${artifact}"
    file="${WORK_DIR}/${artifact}"
    out="${WORK_DIR}/extracted"
    rm -rf "${out}" && mkdir -p "${out}"
    curl -fsSL --retry 3 -o "${file}" "${BASE_URL}/${artifact}"
    case "${suffix}" in
      darwin-*) tar -xzf "${file}" -C "${out}" --wildcards '*/JDK_VERSION' '*/jdk.app/Contents/Home/release' '*/jdk.app/Contents/Home/lib/security/cacerts' ;;
      *.tar.gz) tar -xzf "${file}" -C "${out}" --wildcards '*/JDK_VERSION' '*/jdk/release' '*/jdk/lib/security/cacerts' ;;
      *.zip)    unzip -q "${file}" '*/JDK_VERSION' '*/jdk/release' '*/jdk/lib/security/cacerts' -d "${out}" ;;
      *.deb)    dpkg-deb --fsys-tarfile "${file}" | tar -x -C "${out}" ./usr/share/logstash/JDK_VERSION ./usr/share/logstash/jdk/release ./usr/share/logstash/jdk/lib/security/cacerts ;;
      *.rpm)    (cd "${out}" && rpm2cpio "${file}" | cpio -idm --quiet './usr/share/logstash/JDK_VERSION' './usr/share/logstash/jdk/release' './usr/share/logstash/jdk/lib/security/cacerts') ;;
    esac
    rm -f "${file}"
    jdk_home="$(dirname "$(dirname "$(dirname "$(find "${out}" -path '*/lib/security/cacerts')")")")"
    jdk_version="$(find "${out}" -name JDK_VERSION)"
    "${JAVA}" "${QA_DIR}/BundledJdkTrustCheck.java" artifact "${jdk_home}" "${jdk_version}" "${QA_DIR}/fixtures" || failed+=("${artifact}")
  done
done

if (( ${#failed[@]} )); then
  echo "+++ ${#failed[@]} artifacts failed:"
  printf '  %s\n' "${failed[@]}"
  exit 1
fi
echo "+++ all artifacts passed"
