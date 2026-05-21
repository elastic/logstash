#!/usr/bin/env python3
"""
Generates the Buildkite pipeline step for Snyk stale project cleanup.
"""

import yaml

YAML_HEADER = '# yaml-language-server: $schema=https://raw.githubusercontent.com/buildkite/pipeline-schema/main/schema.json\n'
SCRIPT_PATH = ".buildkite/scripts/snyk/cleanup-stale-projects/run.sh"


def generate_pipeline() -> dict:
    return {
        "steps": [
            {
                "label": ":wastebasket: Delete stale artifact-scan projects",
                "key": "delete-stale-projects",
                "command": SCRIPT_PATH,
                "retry": {"automatic": [{"limit": 2}]},
            },
        ]
    }


if __name__ == "__main__":
    pipeline = generate_pipeline()
    print(YAML_HEADER + yaml.dump(pipeline, default_flow_style=False, sort_keys=False))
