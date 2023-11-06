from dataclasses import dataclass
import subprocess
import typing

import yaml

def get_bk_metadata(key: str) -> typing.List[str]:
    res = subprocess.run(["buildkite-metadata", "get", key], capture_output=True)
    if res.returncode != 0:
        print(f"Failed to retrieve buildkite key [{key}]. Probably something wrong with the pipeline. Exiting.")
        exit(1)
    elif len(res.stdout) == 0:
        print(f"The value of the buildkite key [{key}] was empty. Did you select at least one value? Exiting.")
        exit(1)

    return res.stdout.decode("utf-8").split()

def bk_annotate(job_name_human: str, job_name_slug: str, os: str, jdk: str, status: str) -> str:
  return f"""buildkite-agent annotate "{status} **{job_name_human}** / **{os}** / **{jdk}**" --context={job_name_slug}-{os}-{jdk}"""

@dataclass
class LinuxJobs:
    def __init__(self, os: str, jdk: str):
      self.running_emoji: str = ":bk-status-running:"
      self.success_emoji: str = ":bk-status-passed:"
      self.os = os
      self.jdk = jdk

    def all_jobs(self):
        return [
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

    def java_unit_test(self) -> str:
        job_name_human = "Java Unit Test"
        job_name_slug = "java-unit-test"
        shell_command = f"""
#!/usr/bin/env bash
{self.prepare_shell()}
export ENABLE_SONARQUBE="false"
{bk_annotate(job_name_human, job_name_slug, self.os, self.jdk, self.running_emoji)}
ci/unit_tests.sh java
{bk_annotate(job_name_human, job_name_slug, self.os, self.jdk, self.success_emoji)}
        """

        return job_name_human, job_name_slug, shell_command

    def ruby_unit_test(self) -> str:
        job_name_human = "Ruby Unit Test"
        job_name_slug = "ruby-unit-test"
        shell_command = f"""
#!/usr/bin/env bash
{self.prepare_shell()}
{bk_annotate(job_name_human, job_name_slug, self.os, self.jdk, self.running_emoji)}
ci/unit_tests.sh ruby
{bk_annotate(job_name_human, job_name_slug, self.os, self.jdk, self.success_emoji)}
        """

        return job_name_human, job_name_slug, shell_command

    def integration_tests_part_1(self) -> str:
        return self.integration_tests(part=1)

    def integration_tests_part_2(self) -> str:
        return self.integration_tests(part=2)

    def integration_tests(self, part: str) -> str:
        job_name_human = f"Integration Tests - {part}"
        job_name_slug = f"integration-tests-pt-{part}"
        shell_command = f"""
{self.prepare_shell()}
{bk_annotate(job_name_human, job_name_slug, self.os, self.jdk, self.running_emoji)}
ci/integration_tests.sh split {part-1}
{bk_annotate(job_name_human, job_name_slug, self.os, self.jdk, self.success_emoji)}
        """

        return job_name_human, job_name_slug, shell_command

    def pq_integration_tests_part_1(self) -> str:
        return self.pq_integration_tests(part=1)

    def pq_integration_tests_part_2(self) -> str:
        return self.pq_integration_tests(part=2)

    def pq_integration_tests(self, part: str) -> str:
        job_name_human = f"IT Persistent Queues - {part}"
        job_name_slug = f"it-persistent-queues-pt-{part}"
        shell_command = f"""
{self.prepare_shell()}
{bk_annotate(job_name_human, job_name_slug, self.os, self.jdk, self.running_emoji)}
export FEATURE_FLAG=persistent_queues
ci/integration_tests.sh split {part-1}
{bk_annotate(job_name_human, job_name_slug, self.os, self.jdk, self.success_emoji)}
        """

        return job_name_human, job_name_slug, shell_command

    def x_pack_unit_tests(self) -> str:
        job_name_human = f"x-pack unit tests"
        job_name_slug = "x-pack-unit-tests"
        shell_command = f"""
{self.prepare_shell()}
{bk_annotate(job_name_human, job_name_slug, self.os, self.jdk, self.running_emoji)}
x-pack/ci/unit_tests.sh
{bk_annotate(job_name_human, job_name_slug, self.os, self.jdk, self.success_emoji)}
        """

        return job_name_human, job_name_slug, shell_command

    def x_pack_integration(self) -> str:
        job_name_human = f"x-pack integration"
        job_name_slug = "x-pack-integration"
        shell_command = f"""
{self.prepare_shell()}
{bk_annotate(job_name_human, job_name_slug, self.os, self.jdk, self.running_emoji)}
x-pack/ci/integration_tests.sh
{bk_annotate(job_name_human, job_name_slug, self.os, self.jdk, self.success_emoji)}
        """

        return job_name_human, job_name_slug, shell_command


if __name__ == "__main__":
    matrix_oses = get_bk_metadata(key="matrix-os")
    matrix_jdkes = get_bk_metadata(key="matrix-jdk")

    structure = {"steps": []}


    for matrix_os in matrix_oses:
        for matrix_jdk in matrix_jdkes:
          jobs = LinuxJobs(os=matrix_os, jdk=matrix_jdk)

          for job in jobs.all_jobs():
            job_name_human, job_name_slug, shell_command = job()
            step = {
              "label": f"{matrix_os} / {matrix_jdk} / {job_name_human}",
              "key": job_name_slug,
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

    print(yaml.dump(structure, Dumper=yaml.Dumper, sort_keys=False))
