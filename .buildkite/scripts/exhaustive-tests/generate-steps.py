import json
import os
import random
import sys
import typing

from ruamel.yaml import YAML
from ruamel.yaml.scalarstring import LiteralScalarString

VM_IMAGES_FILE = ".buildkite/scripts/common/vm-images.json"
VM_IMAGE_PREFIX = "platform-ingest-logstash-multi-jdk-"
CUR_PATH = os.path.dirname(os.path.abspath(__file__))

def slugify_bk_key(key: str) -> str:
    """
    Convert and return key to an acceptable format for Buildkite's key: field
    Only alphanumerics, dashes and underscores are allowed.
    """

    mapping_table = str.maketrans({'.': '_', ' ': '_', '/': '_'})

    return key.translate(mapping_table)

def testing_phase_steps() -> typing.Dict[str, typing.List[typing.Any]]:
    with open(os.path.join(CUR_PATH, "..", "..", "pull_request_pipeline.yml")) as fp:
        return YAML().load(fp)

def compat_linux_step(imagesuffix: str) -> dict[str, typing.Any]:
    linux_command = LiteralScalarString("""#!/usr/bin/env bash
set -eo pipefail
source .buildkite/scripts/common/vm-agent.sh
ci/unit_tests.sh""")

    return compat_step(imagesuffix, command=linux_command)


def compat_windows_step(imagesuffix: str) -> dict[str, typing.Any]:
    windows_command = LiteralScalarString(r'''$$env:WORKSPACE=$$PWD.Path ; .\\ci\\unit_tests.bat''')

    return compat_step(imagesuffix, command=windows_command)

def compat_step(imagesuffix: str, command: LiteralScalarString) -> dict[str, typing.Any]:
    step = {
        "label": imagesuffix,
        "key": slugify_bk_key(f"compat-linux-{imagesuffix}"),
        "command": command,
        "agents": {},
    }

    if "amazon" in imagesuffix.lower():
        step["agents"] = {
            "provider": "aws",
            "imagePrefix": f"{VM_IMAGE_PREFIX}{imagesuffix}",
            "instanceType": "m5.2xlarge",
            "diskSizeGb": 200,
       }
    else:
       step["agents"] = {
            "provider": "gcp",
            "imageProject": "elastic-images-prod",
            "image": f"family/{VM_IMAGE_PREFIX}{imagesuffix}",
            "machineType": "n2-standard-4",
            "diskSizeGb": 200,
            "diskType": "pd-ssd",
       }

    return step

def randomized_linux_oses() -> typing.List[str]:
    with open(VM_IMAGES_FILE, "r") as fp:
        all_oses = json.load(fp)

    randomized_oses = []
    for _, family_oses in all_oses["linux"].items():
       randomized_oses.append(random.choice(family_oses))
    return randomized_oses

def randomized_windows_os() -> str:
    with open(VM_IMAGES_FILE, "r") as fp:
        all_oses = json.load(fp)

    return random.choice(all_oses["windows"])

def aws_agent(vm_name: str, instance_type: str, image_prefix: str = "platform-ingest-logstash-multi-jdk", disk_size_gb: int = 200) -> dict[str, typing.Any]:
    return {
        "provider": "aws",
        "imagePrefix": f"{image_prefix}-{vm_name}",
        "instanceType": instance_type,
        "diskSizeGb": disk_size_gb,
    }

def gcp_agent(vm_name: str, instance_type: str = "n2-standard-4", image_prefix: str = "family/platform-ingest-logstash-multi-jdk", disk_size_gb: int = 200) -> dict[str, typing.Any]:
    return {
        "provider": "gcp",
        "imageProject": "elastic-images-prod",
        "image": f"{image_prefix}-{vm_name}",
        "machineType": instance_type,
        "diskSizeGb": disk_size_gb,
        "diskType": "pd-ssd",
    }

def acceptance_docker_steps()-> list[typing.Any]:
    steps = []
    for flavor in ["full", "oss", "ubi8"]:
        steps.append({
            "label": f":docker: {flavor} flavor acceptance",
            "agents": gcp_agent(vm_name="ubuntu-2204", image_prefix="family/platform-ingest-logstash"),
            "command": LiteralScalarString(f"""#!/usr/bin/env bash
set -euo pipefail
source .buildkite/scripts/common/vm-agent.sh
ci/docker_acceptance_tests.sh {flavor}"""),
        })

    return steps

if __name__ == "__main__":
    LINUX_OS_ENV_VAR_OVERRIDE = os.getenv("LINUX_OS")
    WINDOWS_OS_ENV_VAR_OVERRIDE = os.getenv("WINDOWS_OS")

    compat_linux_steps = []
    linux_test_oses = [LINUX_OS_ENV_VAR_OVERRIDE] if LINUX_OS_ENV_VAR_OVERRIDE else randomized_linux_oses()
    for linux_os in linux_test_oses:
       compat_linux_steps.append(compat_linux_step(linux_os))

    windows_test_os = WINDOWS_OS_ENV_VAR_OVERRIDE or randomized_windows_os()

    structure = {"steps": []}

    structure["steps"].append({
        "group": "Testing Phase",
        "key": "testing-phase",
        **testing_phase_steps(),
    })

    structure["steps"].append({
            "group": "Compatibility / Linux",
            "key": "compatibility-linux",
            "depends_on": "testing-phase",
            "steps": compat_linux_steps,
    })

    structure["steps"].append({
            "group": "Compatibility / Windows",
            "key": "compatibility-windows",
            "depends_on": "testing-phase",
            "steps": [compat_windows_step(imagesuffix=windows_test_os)],
    })

    structure["steps"].append({
            "group": "Acceptance / Docker",
            "key": "acceptance-docker",
            "depends_on": ["testing-phase"],
            "steps": acceptance_docker_steps(),
    })

    print('# yaml-language-server: $schema=https://raw.githubusercontent.com/buildkite/pipeline-schema/main/schema.json')
    YAML().dump(structure, sys.stdout)
