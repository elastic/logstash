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
            Resolves Logstash branch considering provided LS_VERSION
            Checks out git branch
        """
        logstash_version = os.environ.get("LS_VERSION")
        if logstash_version is None:
            # version is not specified, use the main branch, no need to git checkout
            print(f"LS_VERSION is not specified, using main branch.")
        else:
            # LS_VERSION accepts major latest as a major.x or specific version as X.Y
            if logstash_version.find(".x") == -1:
                print(f"Using specified branch: {logstash_version}")
                util.git_check_out_branch(logstash_version)
            else:
                major_version = logstash_version.split(".")[0]
                if major_version and major_version.isnumeric():
                    resolved_version = self.__resolve_latest_stack_version_for(major_version)
                    minor_version = resolved_version.split(".")[1]
                    branch = major_version + "." + minor_version
                    print(f"Using resolved branch: {branch}")
                    util.git_check_out_branch(branch)
                else:
                    raise ValueError(f"Invalid value set to LS_VERSION. Please set it properly (ex: 8.x or 9.0) and "
                                     f"rerun again")

    def __resolve_latest_stack_version_for(self, major_version: str) -> None:
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
        print(f"Building Logstash.")
        util.run_or_raise_error(
            ["./gradlew", "clean", "bootstrap", "assemble", "installDefaultGems"],
            "Failed to build Logstash")
        print(f"Logstash has successfully built.")

    def apply_config(self, config: dict) -> None:
        with open(os.getcwd() + "/config/pipelines.yml", 'w') as pipelines_file:
            yaml.dump(config, pipelines_file)

    def run_logstash(self) -> subprocess.Popen:
        process = subprocess.Popen(["bin/logstash"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if process.poll() is not None:
            print(f"Logstash failed to run, check the the config and logs, then rerun.")
            return None

        # Read stdout and stderr in real-time
        logs = []
        for stdout_line in iter(process.stdout.readline, ""):
            # print("STDOUT:", stdout_line.strip())
            logs.append(stdout_line.strip())
            if "Starting pipeline" in stdout_line:
                break
            if "Logstash shut down" in stdout_line:
                print(f"Logstash couldn't spin up.")
                print(logs)
                return None

        print(f"Logstash is running with PID: {process.pid}.")
        return process

    def stop_logstash(self, process: subprocess.Popen) -> None:
        process.terminate()
        print(f"Stopping Logstash...")
