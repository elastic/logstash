"""
Health Report Integration test bootstrapper with Python script
    - A script to resolve Logstash version if not provided
    - Download LS docker image and spin up
    - When tests finished, teardown the Logstash
"""
import os
import subprocess
import util
import yaml


class Bootstrap:
    ELASTIC_STACK_VERSIONS_URL = "https://artifacts-api.elastic.co/v1/versions"

    def __init__(self) -> None:
        f"""
        A constructor of the {Bootstrap}.
        Returns:
            Resolves Logstash branch considering provided LS_BRANCH
            Checks out git branch
        """
        logstash_branch = os.environ.get("LS_BRANCH")
        if logstash_branch is None:
            # version is not specified, use the main branch, no need to git checkout
            print(f"LS_BRANCH is not specified, using main branch.")
        else:
            # LS_BRANCH accepts major latest as a major.x or specific branch as X.Y
            if logstash_branch.find(".x") == -1:
                print(f"Using specified branch: {logstash_branch}")
                util.git_check_out_branch(logstash_branch)
            else:
                major_version = logstash_branch.split(".")[0]
                if major_version and major_version.isnumeric():
                    resolved_version = self.__resolve_latest_stack_version_for(major_version)
                    minor_version = resolved_version.split(".")[1]
                    branch = major_version + "." + minor_version
                    print(f"Using resolved branch: {branch}")
                    util.git_check_out_branch(branch)
                else:
                    raise ValueError(f"Invalid value set to LS_BRANCH. Please set it properly (ex: 8.x or 9.0) and "
                                     f"rerun again")

    def __resolve_latest_stack_version_for(self, major_version: str) -> str:
        resolved_version = ""
        response = util.call_url_with_retry(self.ELASTIC_STACK_VERSIONS_URL)
        release_versions = response.json()["versions"]
        for release_version in reversed(release_versions):
            if release_version.find("SNAPSHOT") > 0:
                continue
            if release_version.split(".")[0] == major_version:
                print(f"Resolved latest version for {major_version} is {release_version}.")
                resolved_version = release_version
                break

        if resolved_version == "":
            raise ValueError(f"Cannot resolve latest version for {major_version} major")
        return resolved_version

    def install_plugin(self, plugin_path: str) -> None:
        util.run_or_raise_error(
            ["bin/logstash-plugin", "install", plugin_path],
            f"Failed to install {plugin_path}")

    def build_logstash(self):
        print(f"Building Logstash...")
        util.run_or_raise_error(
            ["./gradlew", "clean", "bootstrap", "assemble", "installDefaultGems"],
            "Failed to build Logstash")
        print(f"Logstash has successfully built.")

    def apply_config(self, config: dict) -> None:
        with open(os.getcwd() + "/.buildkite/scripts/health-report-tests/config/pipelines.yml", 'w') as pipelines_file:
            yaml.dump(config, pipelines_file)

    def run_logstash(self, full_start_required: bool) -> subprocess.Popen:
        # --config.reload.automatic is to make instance active
        # it is helpful when testing crash pipeline cases
        config_path = os.getcwd() + "/.buildkite/scripts/health-report-tests/config"
        process = subprocess.Popen(["bin/logstash", "--config.reload.automatic", "--path.settings", config_path,
                                    "-w 1"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, shell=False)
        if process.poll() is not None:
            print(f"Logstash failed to run, check the the config and logs, then rerun.")
            return None

        # Read stdout and stderr in real-time
        logs = []
        for stdout_line in iter(process.stdout.readline, ""):
            logs.append(stdout_line.strip())
            # we don't wait for Logstash fully start as we also test slow pipeline start scenarios
            if full_start_required is False and "Starting pipeline" in stdout_line:
                break
            if full_start_required is True and "Pipeline started" in stdout_line:
                break
            if "Logstash shut down" in stdout_line or "Logstash stopped" in stdout_line:
                print(f"Logstash couldn't spin up.")
                print(logs)
                return None

        print(f"Logstash is running with PID: {process.pid}.")
        return process
