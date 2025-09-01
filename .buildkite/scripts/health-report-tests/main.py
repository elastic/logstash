"""
 Main entry point of the LS health report API integration test suites
"""
import glob
import os
import time
import traceback
import yaml
from bootstrap import Bootstrap
from scenario_executor import ScenarioExecutor
from config_validator import ConfigValidator


class BootstrapContextManager:

    def __init__(self):
        pass

    def __enter__(self):
        print(f"Starting Logstash Health Report Integration test.")
        self.bootstrap = Bootstrap()
        self.bootstrap.build_logstash()

        plugin_path = os.getcwd() + "/qa/support/logstash-integration-failure_injector/logstash-integration" \
                                    "-failure_injector-*.gem"
        matching_files = glob.glob(plugin_path)
        if len(matching_files) == 0:
            raise ValueError(f"Could not find logstash-integration-failure_injector plugin.")

        self.bootstrap.install_plugin(matching_files[0])
        print("logstash-integration-failure_injector successfully installed.")
        return self.bootstrap

    def __exit__(self, exc_type, exc_value, exc_traceback):
        if exc_type is not None:
            print(traceback.format_exception(exc_type, exc_value, exc_traceback))


def main():
    with BootstrapContextManager() as bootstrap:
        scenario_executor = ScenarioExecutor()
        config_validator = ConfigValidator()

        working_dir = os.getcwd()
        scenario_files_path = working_dir + "/.buildkite/scripts/health-report-tests/tests/*.yaml"
        scenario_files = glob.glob(scenario_files_path)

        for scenario_file in scenario_files:
            print(f"Validating {scenario_file} scenario file.")
            config_validator.load(scenario_file)
            if config_validator.is_valid() is False:
                print(f"{scenario_file} scenario file is not valid.")
                return
            else:
                print(f"Validation succeeded.")

        has_failed_scenario = False
        for scenario_file in scenario_files:
            with open(scenario_file, 'r') as file:
                # scenario_content: Dict[str, Any] = None
                scenario_content = yaml.safe_load(file)
                print(f"Testing `{scenario_content.get('name')}` scenario.")
                scenario_name = scenario_content['name']

                is_full_start_required = scenario_content.get('conditions').get('full_start_required')
                wait_seconds = scenario_content.get('conditions').get('wait_seconds')
                config = scenario_content['config']
                if config is not None:
                    bootstrap.apply_config(config)
                    expectations = scenario_content.get("expectation")
                    process = bootstrap.run_logstash(is_full_start_required)
                    if process is not None:
                        if wait_seconds is not None:
                            print(f"Test requires to wait for `{wait_seconds}` seconds.")
                            time.sleep(wait_seconds)  # wait for Logstash to start
                        try:
                            scenario_executor.on(scenario_name, expectations)
                        except Exception as e:
                            print(e)
                            has_failed_scenario = True
                        bootstrap.stop_logstash(process)

        if has_failed_scenario:
            # intentionally fail due to visibility
            raise Exception("Some of scenarios failed, check the log for details.")


if __name__ == "__main__":
    main()
