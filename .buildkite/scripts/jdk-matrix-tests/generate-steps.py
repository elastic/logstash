import os
import typing

import yaml

def get_bk_metadata(key: str) -> typing.List[str]:
    try:
      return os.environ[key].split()
    except KeyError:
        print(f"Missing environment variable [{key}]. This should be set before calling this script using buildkite-agent meta-data get. Exiting.")
        exit(1)

def bk_annotate(job_name_human: str, job_name_slug: str, os: str, jdk: str, status: str) -> str:
  return f"""buildkite-agent annotate "{status} **{job_name_human}** / **{os}** / **{jdk}**" --context={job_name_slug}-{os}-{jdk}"""


class LinuxJobs:
    def __init__(self, os: str, jdk: str):
      self.running_emoji: str = ":bk-status-running:"
      self.success_emoji: str = ":bk-status-passed:"
      self.failed_emoji: str = ":bk-status-failed:"
      self.os = os
      self.jdk = jdk

    def all_jobs(self) -> list[typing.Callable[[], typing.Tuple[str, str]]]:
        return [
            self.java_unit_test,
            self.ruby_unit_test,
            ## temporarily disabled due to https://github.com/elastic/logstash/issues/15529
            # self.integration_tests_part_1,
            self.integration_tests_part_2,
            ## temporarily disabled due to https://github.com/elastic/logstash/issues/15529
            # self.pq_integration_tests_part_1,
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

    def emit_command(self, job_name_human, job_name_slug, test_command: str) -> str:
      return f"""
{self.prepare_shell()}
{bk_annotate(job_name_human, job_name_slug, self.os, self.jdk, self.running_emoji)}
# temporarily disable immediately failure on error, so that we can update the BK annotation
set +eo pipefail
{test_command}
if [[ $? -neq 0 ]]; then
  {bk_annotate(job_name_human, job_name_slug, self.os, self.jdk, self.failed_emoji)}
  exit 1
else
  {bk_annotate(job_name_human, job_name_slug, self.os, self.jdk, self.success_emoji)}
fi
      """        
    def java_unit_test(self) -> typing.Tuple[str, str]:
        job_name_human = "Java Unit Test"
        job_name_slug = "java-unit-test"
        test_command = '''
export ENABLE_SONARQUBE="false"
ci/unit_tests.sh java
        '''

        return job_name_human, self.emit_command(job_name_human, job_name_slug, test_command)

    def ruby_unit_test(self) -> typing.Tuple[str, str]:
        job_name_human = "Ruby Unit Test"
        job_name_slug = "ruby-unit-test"
        test_command = """
ci/unit_tests.sh ruby
        """

        return job_name_human, self.emit_command(job_name_human, job_name_slug, test_command)

    def integration_tests_part_1(self) -> typing.Tuple[str, str]:
        return self.integration_tests(part=1)

    def integration_tests_part_2(self) -> typing.Tuple[str, str]:
        return self.integration_tests(part=2)

    def integration_tests(self, part: int) -> typing.Tuple[str, str]:
        job_name_human = f"Integration Tests - {part}"
        job_name_slug = f"integration-tests-pt-{part}"
        test_command = f"""
ci/integration_tests.sh split {part-1}
        """

        return job_name_human, self.emit_command(job_name_human, job_name_slug, test_command)

    def pq_integration_tests_part_1(self) -> typing.Tuple[str, str]:
        return self.pq_integration_tests(part=1)

    def pq_integration_tests_part_2(self) -> typing.Tuple[str, str]:
        return self.pq_integration_tests(part=2)

    def pq_integration_tests(self, part: int) -> typing.Tuple[str, str]:
        job_name_human = f"IT Persistent Queues - {part}"
        job_name_slug = f"it-persistent-queues-pt-{part}"
        test_command = f"""
export FEATURE_FLAG=persistent_queues
ci/integration_tests.sh split {part-1}
        """

        return job_name_human, self.emit_command(job_name_human, job_name_slug, test_command)

    def x_pack_unit_tests(self) -> typing.Tuple[str, str]:
        job_name_human = "x-pack unit tests"
        job_name_slug = "x-pack-unit-tests"
        test_command = """
x-pack/ci/unit_tests.sh
        """

        return job_name_human, self.emit_command(job_name_human, job_name_slug, test_command)

    def x_pack_integration(self) -> typing.Tuple[str, str]:
        job_name_human = "x-pack integration"
        job_name_slug = "x-pack-integration"
        test_command = """
x-pack/ci/integration_tests.sh
        """

        return job_name_human, self.emit_command(job_name_human, job_name_slug, test_command)


if __name__ == "__main__":
    matrix_oses = get_bk_metadata(key="MATRIX_OSES")
    matrix_jdkes = get_bk_metadata(key="MATRIX_JDKS")

    structure = {"steps": []}


    for matrix_os in matrix_oses:
        for matrix_jdk in matrix_jdkes:
          jobs = LinuxJobs(os=matrix_os, jdk=matrix_jdk)

          for job in jobs.all_jobs():
            job_name_human, shell_command = job()
            step = {
              "label": f"{matrix_os} / {matrix_jdk} / {job_name_human}",
              "agents": {
                  "provider": "gcp",
                  "imageProject": "elastic-images-qa",
                  "image": f"family/platform-ingest-logstash-multi-jdk-{matrix_os}",
                  "machineType": "n2-standard-4",
                  "diskSizeGb": 200,
                  "diskType": "pd-ssd",
                },
                "command": shell_command,
            }

            structure["steps"].append(step)

    print(yaml.dump(data=structure, Dumper=yaml.Dumper, sort_keys=False))
