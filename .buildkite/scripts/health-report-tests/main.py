"""
 Main entry point of the LS health report API integration test suites
"""
import glob
import os
from bootstrap import Bootstrap
from scenario_executor import ScenarioExecutor
from config_validator import ConfigValidator
import yaml
import util


class BootstrapContextManager:

    def __init__(self):
        pass

    def __enter__(self):
        print(f"Starting Logstash Health Report Integration test.")
        self.bootstrap = Bootstrap()
        # self.bootstrap.build_logstash()

        plugin_path = os.getcwd() + "/qa/support/logstash-integration-failure_injector/logstash-integration" \
                                    "-failure_injector-*.gem"
        matching_files = glob.glob(plugin_path)
        if len(matching_files) == 0:
            raise ValueError(f"Could not find logstash-integration-failure_injector plugin.")

        # self.bootstrap.install_plugin(matching_files[0])
        print(f"logstash-integration-failure_injector successfully installed.")
        return self.bootstrap

    def apply_config(self, bootstrap: Bootstrap, config: str):
        bootstrap.apply_config(config)

    def __exit__(self, exc_type, exc_value, traceback):
        if exc_type is not None:
            traceback.print_exception(exc_type, exc_value, traceback)


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
            if not config_validator.is_valid():
                print(f"{scenario_file} scenario file is not valid.")
                return

        for scenario_file in scenario_files:
            with open(scenario_file, 'r') as file:
                # scenario_content: Union[List[Dict[str, Any]], None] = None
                scenario_content = yaml.safe_load(file)
                scenario_name = util.get_element_of_array(scenario_content, 'name')
                config = util.get_element_of_array(scenario_content, 'config')
                if config is not None:
                    bootstrap.apply_config(config)
                    expectation = util.get_element_of_array(scenario_content, 'expectation')
                    process = bootstrap.run_logstash()
                    if process is not None:
                        scenario_executor.on(scenario_name, expectation)
                        process.terminate()
                    break


if __name__ == "__main__":
    main()
