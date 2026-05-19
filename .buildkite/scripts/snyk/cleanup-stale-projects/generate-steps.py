#!/usr/bin/env python3
"""
Generates Buildkite pipeline steps for Snyk stale project cleanup.
Produces two sequential steps: deactivate stale projects, then delete inactive ones.
"""

import os
import yaml

YAML_HEADER = '# yaml-language-server: $schema=https://raw.githubusercontent.com/buildkite/pipeline-schema/main/schema.json\n'
SCRIPT_PATH = ".buildkite/scripts/snyk/cleanup-stale-projects/run.sh"


def generate_pipeline() -> dict:
    return {
        "steps": [
            {
                "label": ":deactivate: Deactivate stale artifact-scan projects",
                "key": "deactivate-stale-projects",
                "command": f"{SCRIPT_PATH} deactivate",
                "retry": {"automatic": [{"limit": 2}]},
            },
            {
                "label": ":wastebasket: Delete inactive artifact-scan projects",
                "key": "delete-inactive-projects",
                "depends_on": "deactivate-stale-projects",
                "command": f"{SCRIPT_PATH} delete",
                "retry": {"automatic": [{"limit": 2}]},
            },
        ]
    }


if __name__ == "__main__":
    pipeline = generate_pipeline()
    print(YAML_HEADER + yaml.dump(pipeline, default_flow_style=False, sort_keys=False))
