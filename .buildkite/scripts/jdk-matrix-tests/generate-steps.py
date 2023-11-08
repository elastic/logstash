import abc
from dataclasses import dataclass
import os
import sys
import typing

from ruamel.yaml import YAML
from ruamel.yaml.scalarstring import LiteralScalarString


@dataclass
class JobRetValues:
    step_label: str
    command: str
    step_key: str
    depends: str
    default_agent: bool = False

@dataclass
class BuildkiteEmojis:
    running: str = ":bk-status-running:"
    success: str = ":bk-status-passed:"
    failed: str = ":bk-status-failed:"

def slugify_bk_key(key: str) -> str:
    """
    Convert and return key to an acceptable format for Buildkite's key: field
    Only alphanumerics, dashes and underscores are allowed.
    """

    mapping_table = str.maketrans({'.': '_', ' ': '_', '/': '_'})

    return key.translate(mapping_table)

def get_bk_metadata(key: str) -> typing.List[str]:
    try:
      return os.environ[key].split()
    except KeyError:
        print(f"Missing environment variable [{key}]. This should be set before calling this script using buildkite-agent meta-data get. Exiting.")
        exit(1)

def bk_annotate(body: str, context: str, mode = "") -> str:
    cmd = f"""buildkite-agent annotate --style=info --context={context} """
    if mode:
        cmd += f"--{mode} "

    cmd += f"\"{body}\n\""
    return cmd


class Jobs(abc.ABC):
    def __init__(self, os: str, jdk: str, group_key: str):
        self.os = os
        self.jdk = jdk
        self.group_key = group_key
        self.init_annotation_key = f"{os}-{jdk}-initialize-annotation"

    def init_annotation(self) -> JobRetValues:
        """
        Command for creating the header of a new annotation for a group step
        """

        body = f"### Group: {self.os} / {self.jdk}\n| **Status** | **Test** |\n| --- | ----|"

        return JobRetValues(
            step_label="Initialize annotation",
            command=LiteralScalarString(bk_annotate(body=body, context=self.group_key)),
            step_key=self.init_annotation_key,
            depends="",
            default_agent=True,
        )

    @abc.abstractmethod
    def all_jobs(self) -> list[typing.Callable[[], typing.Tuple[str, str]]]:
        pass


class WindowsJobs(Jobs):
    def __init__(self, os: str, jdk: str, group_key: str):
      super().__init__(os=os, jdk=jdk, group_key=group_key)

    def all_jobs(self) -> list[typing.Callable[[], JobRetValues]]:
        return [
          self.unit_tests,
        ]

    def unit_tests(self) -> JobRetValues:
        step_name_human = "Java Unit Test"
        test_command = "# TODO"

        return JobRetValues(
            step_label=step_name_human,
            command=test_command,
            step_key="java-unit-test",
            depends="",
        )
        return step_name_human, test_command
      

class LinuxJobs(Jobs):
    def __init__(self, os: str, jdk: str, group_key: str):
      super().__init__(os=os, jdk=jdk, group_key=group_key)

    def all_jobs(self) -> list[typing.Callable[[], JobRetValues]]:
        return [
            self.init_annotation,
            self.java_unit_test,
            self.ruby_unit_test,
            self.integration_tests_part_1,
            self.integration_tests_part_2,
            self.pq_integration_tests_part_1,
            self.pq_integration_tests_part_2,
            self.x_pack_unit_tests,
            self.x_pack_integration,
        ]

    def prepare_shell(self) -> str:
        jdk_dir = f"/opt/buildkite-agent/.java/{self.jdk}"
        return f"""#!/usr/bin/env bash
set -euo pipefail

# unset generic JAVA_HOME
unset JAVA_HOME

# LS env vars for JDK matrix tests
export BUILD_JAVA_HOME={jdk_dir}
export RUNTIME_JAVA_HOME={jdk_dir}
export LS_JAVA_HOME={jdk_dir}

export PATH="/opt/buildkite-agent/.rbenv/bin:/opt/buildkite-agent/.pyenv/bin:$PATH"
eval "$(rbenv init -)"
"""

    def failed_step_annotation(self, step_name_human) -> str:
        return bk_annotate(body=f"| {BuildkiteEmojis.failed} | {step_name_human} |", context=self.group_key, mode="append")

    def succeeded_step_annotation(self, step_name_human) -> str:
        return bk_annotate(body=f"| {BuildkiteEmojis.success} | {step_name_human} |", context=self.group_key, mode="append")

    def emit_command(self, step_name_human, test_command: str) -> str:
        return LiteralScalarString(f"""
{self.prepare_shell()}
# temporarily disable immediate failure on errors, so that we can update the BK annotation
set +eo pipefail
{test_command}
if [[ $$? -ne 0 ]]; then
    {self.failed_step_annotation(step_name_human)}
  exit 1
else
    {self.succeeded_step_annotation(step_name_human)}
fi
      """)

    def java_unit_test(self) -> JobRetValues:
        step_name_human = "Java Unit Test"
        step_key = f"{self.group_key}-java-unit-test"
        test_command = '''
export ENABLE_SONARQUBE="false"
ci/unit_tests.sh java
        '''

        return JobRetValues(
            step_label=step_name_human,
            command=self.emit_command(step_name_human, test_command),
            step_key=step_key,
            depends=self.init_annotation_key,
        )

    def ruby_unit_test(self) -> JobRetValues:
        step_name_human = "Ruby Unit Test"
        step_key = f"{self.group_key}-ruby-unit-test"
        test_command = """
ci/unit_tests.sh ruby
        """

        return JobRetValues(
            step_label=step_name_human,
            command=self.emit_command(step_name_human, test_command),
            step_key=step_key,
            depends=self.init_annotation_key,
        )

    def integration_tests_part_1(self) -> JobRetValues:
        return self.integration_tests(part=1)

    def integration_tests_part_2(self) -> JobRetValues:
        return self.integration_tests(part=2)

    def integration_tests(self, part: int) -> JobRetValues:
        step_name_human = f"Integration Tests - {part}"
        step_key = f"{self.group_key}-integration-tests-{part}"
        test_command = f"""
ci/integration_tests.sh split {part-1}
        """

        return JobRetValues(
            step_label=step_name_human,
            command=self.emit_command(step_name_human, test_command),
            step_key=step_key,
            depends=self.init_annotation_key,
        )

    def pq_integration_tests_part_1(self) -> JobRetValues:
        return self.pq_integration_tests(part=1)

    def pq_integration_tests_part_2(self) -> JobRetValues:
        return self.pq_integration_tests(part=2)

    def pq_integration_tests(self, part: int) -> JobRetValues:
        step_name_human = f"IT Persistent Queues - {part}"
        step_key = f"{self.group_key}-it-persistent-queues-{part}"
        test_command = f"""
export FEATURE_FLAG=persistent_queues
ci/integration_tests.sh split {part-1}
        """

        return JobRetValues(
            step_label=step_name_human,
            command=self.emit_command(step_name_human, test_command),
            step_key=step_key,
            depends=self.init_annotation_key,
        )

    def x_pack_unit_tests(self) -> JobRetValues:
        step_name_human = "x-pack unit tests"
        step_key = f"{self.group_key}-x-pack-unit-test"
        test_command = """
x-pack/ci/unit_tests.sh
        """

        return JobRetValues(
            step_label=step_name_human,
            command=self.emit_command(step_name_human, test_command),
            step_key=step_key,
            depends=self.init_annotation_key,
        )

    def x_pack_integration(self) -> JobRetValues:
        step_name_human = "x-pack integration"
        step_key = f"{self.group_key}-x-pack-integration"
        test_command = """
x-pack/ci/integration_tests.sh
        """

        return JobRetValues(
            step_label=step_name_human,
            command=self.emit_command(step_name_human, test_command),
            step_key=step_key,
            depends=self.init_annotation_key,
        )


if __name__ == "__main__":
    matrix_oses = get_bk_metadata(key="MATRIX_OSES")
    matrix_jdkes = get_bk_metadata(key="MATRIX_JDKS")

    pipeline_name = os.environ.get("BUILDKITE_PIPELINE_NAME", "").lower()

    structure = {"steps": []}


    for matrix_os in matrix_oses:
        for matrix_jdk in matrix_jdkes:
          group_name = f"{matrix_os}/{matrix_jdk}"
          group_key = slugify_bk_key(group_name)

          if "windows" in pipeline_name:
            jobs = WindowsJobs(os=matrix_os, jdk=matrix_jdk, group_key=group_key)
          else:
            jobs = LinuxJobs(os=matrix_os, jdk=matrix_jdk, group_key=group_key)

          group_steps = []
          for job in jobs.all_jobs():
            job_values = job()

            step = {
              "label": f"{matrix_os} / {matrix_jdk} / {job_values.step_label}",
              "key": job_values.step_key,
            }

            if job_values.depends:
                step["depends_on"] = job_values.depends

            if not job_values.default_agent:
                step["agents"] = {
                    "provider": "gcp",
                    "imageProject": "elastic-images-qa",
                    "image": f"family/platform-ingest-logstash-multi-jdk-{matrix_os}",
                    "machineType": "n2-standard-4",
                    "diskSizeGb": 200,
                    "diskType": "pd-ssd",
                }


            step["command"] = job_values.command

            group_steps.append(step)


          structure["steps"].append({
            "group": group_name,
            "key": slugify_bk_key(group_name),
            "steps": group_steps})


    YAML().dump(structure, sys.stdout)
