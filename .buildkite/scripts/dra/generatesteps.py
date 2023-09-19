import os
import sys

import yaml

def to_bk_key_friendly_string(key):
    """
    Convert and return key to an acceptable format for Buildkite's key: field
    Only alphanumerics, dashes and underscores are allowed.
    """

    mapping_table = str.maketrans({'.': '_'})

    return key.translate(mapping_table)

def package_x86_step(branch, version_qualifier, workflow_type):
    step_key = to_bk_key_friendly_string(f"logstash_build_x86_64_dra_{branch}_{workflow_type}")

    step = f'''
- label: ":package: Build x86_64 {branch}-{workflow_type.upper()} DRA artifacts"
  key: "{step_key}"
  agents:
    image: "docker.elastic.co/ci-agent-images/platform-ingest/buildkite-agent-logstash-ci:0.2"
    cpu: "8"
    memory: "8Gi"
    ephemeralStorage: "100Gi"
  command: |
    export VERSION_QUALIFIER_OPT={version_qualifier}
    export WORKFLOW_TYPE={workflow_type}
    export PATH="/usr/local/rbenv/bin:$PATH"
    eval "$(rbenv init -)"
    .buildkite/scripts/dra/dra_x86_64.sh
    buildkite-agent artifact upload "build/logstash*;build/distributions/**/*"
  branches: "{branch}"
'''

    return step

def publish_dra_step(branch, version_qualifier, workflow_type):
    step_key = to_bk_key_friendly_string(f"logstash_publish_dra_{branch}_{workflow_type}")

    step = f'''
- label: ":elastic-stack: Publish {branch}-{workflow_type.upper()} DRA artifacts"
  key: {step_key}
  depends_on: "package_{branch}"
  agents:
    provider: gcp
    imageProject: elastic-images-qa
    image: family/platform-ingest-logstash-ubuntu-2204
    machineType: "n2-standard-16"
  command: |
    echo "+++ Restoring Artifacts"
    buildkite-agent artifact download "build/logstash*" . --step logstash_x86_64_dra_{branch}_{workflow_type}
    buildkite-agent artifact download "build/distributions/**/*" . --step logstash_x86_64_dra_{branch}_{workflow_type}
    echo "+++ Changing permissions for the release manager"
    sudo chown -R :1000 build
    echo "+++ Running DRA publish step"
    ls -laRt build
  branches: "{branch}"
    '''

    return step

def build_steps_to_yaml(branch, version_qualifier, workflow_type):
    steps = []
    steps.extend(yaml.safe_load(package_x86_step(branch, version_qualifier, workflow_type)))

    return steps

if __name__ == "__main__":
    try:
        WORKFLOW_TYPE = os.environ["WORKFLOW_TYPE"]
    except ImportError:
        print(f"Missing required cli argument for workflow type. Use:\n{sys.argv[0]} <staging|snapshot>\n.Exiting.")
        exit(1)

    BRANCHES = [os.environ["BRANCH"]]
    if not BRANCHES[0].strip():
        BRANCHES = ["main", "8.10", "7.17"]

    # these come from input: fields in the buildkite pipeline definition
    VERSION_QUALIFIER = os.environ["VERSION_QUALIFIER"]

    structure = {"steps": []}

    for branch in BRANCHES:
        # Group defining parallel steps that build and save artifacts
        group_key = to_bk_key_friendly_string(f"logstash_dra_{branch}_{WORKFLOW_TYPE}")

        structure["steps"].append({
            "group": f":Build Artifacts - {branch}-{WORKFLOW_TYPE.upper()}",
            "key": group_key,
            "steps": build_steps_to_yaml(branch, VERSION_QUALIFIER, WORKFLOW_TYPE),
        })

        # Final step: pull artifacts built above and publish them via the release-manager
        structure["steps"].extend(
            yaml.safe_load(publish_dra_step(branch, VERSION_QUALIFIER, WORKFLOW_TYPE))
        )

    print(yaml.dump(structure, Dumper=yaml.Dumper, sort_keys=False))
