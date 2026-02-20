#!/usr/bin/env python3

import os
import requests
import yaml

YAML_HEADER = '# yaml-language-server: $schema=https://raw.githubusercontent.com/buildkite/pipeline-schema/main/schema.json\n'
VERSIONS_URL = "https://raw.githubusercontent.com/logstash-plugins/.ci/1.x/logstash-versions.yml"

TEST_MATRIX = [
    ("x86_64", "deb", "ubuntu-2204", "gcp", "n2-standard-4"),
    ("x86_64", "rpm", "almalinux-8", "gcp", "n2-standard-4"),
    ("arm64", "deb", "ubuntu-2204-aarch64", "aws", "m6g.4xlarge"),
    ("arm64", "rpm", "almalinux-8-aarch64", "aws", "m6g.4xlarge"),
]


def fetch_logstash_versions():
    response = requests.get(VERSIONS_URL, timeout=30)
    response.raise_for_status()
    return yaml.safe_load(response.text)


def slugify_bk_key(key):
    return key.replace(".", "-").replace(" ", "-").replace("/", "-").lower()


def aws_agent(vm_name, instance_type):
    return {
        "provider": "aws",
        "imagePrefix": f"platform-ingest-logstash-{vm_name}",
        "instanceType": instance_type,
        "diskSizeGb": 200,
    }


def gcp_agent(vm_name, instance_type):
    return {
        "provider": "gcp",
        "imageProject": "elastic-images-prod",
        "image": f"family/platform-ingest-logstash-multi-jdk-{vm_name}",
        "machineType": instance_type,
        "diskSizeGb": 200,
        "diskType": "pd-ssd",
    }


def generate_test_step(version, artifact_type, arch, pkg_type, vm_name, provider, instance_type):
    agent = aws_agent(vm_name, instance_type) if provider == "aws" else gcp_agent(vm_name, instance_type)
    return {
        "label": f"{version} / {arch} / {pkg_type}",
        "key": slugify_bk_key(f"test-{version}-{arch}-{pkg_type}"),
        "agents": agent,
        "env": {
            "LS_VERSION": version,
            "ARTIFACT_TYPE": artifact_type,
            "PKG_TYPE": pkg_type,
            "ARCH": arch,
        },
        "command": ".buildkite/scripts/exhaustive-tests/run-acceptance-from-artifact.sh",
        "retry": {"automatic": [{"limit": 3}]},
    }


if __name__ == "__main__":
    artifact_type = os.getenv("ARTIFACT_TYPE", "snapshot")
    versions_data = fetch_logstash_versions()
    versions_dict = versions_data.get("snapshots" if artifact_type == "snapshot" else "releases", {})
    versions = list(versions_dict.values())

    steps = []
    for version in versions:
        for arch, pkg_type, vm_name, provider, instance_type in TEST_MATRIX:
            steps.append(generate_test_step(version, artifact_type, arch, pkg_type, vm_name, provider, instance_type))

    pipeline = {
        "steps": [{
            "group": f"Acceptance Tests ({artifact_type.capitalize()} Artifacts)",
            "key": f"acceptance-{artifact_type}",
            "steps": steps,
        }]
    }

    print(YAML_HEADER + yaml.dump(pipeline, default_flow_style=False, sort_keys=False))
