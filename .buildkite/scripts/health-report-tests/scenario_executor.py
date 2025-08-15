"""
A class to execute the given scenario for Logstash Health Report integration test
"""
import time
from logstash_health_report import LogstashHealthReport


class ScenarioExecutor:
    logstash_health_report_api = LogstashHealthReport()

    def __init__(self):
        pass

    def __has_intersection(self, expects, results):
        # TODO: this logic is aligned on current Health API response
        #   there is no guarantee that method correctly runs if provided multi expects and results
        # we expect expects to be existing in results
        for expect in expects:
            for result in results:
                if result.get('help_url') and "health-report-pipeline-" not in result.get('help_url'):
                    return False
                if not all(key in result and result[key] == value for key, value in expect.items()):
                    return False
        return True

    def __get_difference(self, differences: list, expectations: dict, reports: dict) -> dict:
        for key in expectations.keys():

            if type(expectations.get(key)) != type(reports.get(key)):
                differences.append(f"Scenario expectation and Health API report structure differs for {key}.")
                return differences

            if isinstance(expectations.get(key), str):
                if expectations.get(key) != reports.get(key):
                    differences.append({key: {"expected": expectations.get(key), "got": reports.get(key)}})
                continue
            elif isinstance(expectations.get(key), dict):
                self.__get_difference(differences, expectations.get(key), reports.get(key))
            elif isinstance(expectations.get(key), list):
                if not self.__has_intersection(expectations.get(key), reports.get(key)):
                    differences.append({key: {"expected": expectations.get(key), "got": reports.get(key)}})
        return differences

    def __is_expected(self, expectations: dict) -> None:
        reports = self.logstash_health_report_api.get()
        differences = self.__get_difference([], expectations, reports)
        if differences:
            print("Differences found in 'expectation' section between YAML content and stats:")
            for diff in differences:
                print(f"Difference: {diff}")
            return False
        else:
            return True

    def on(self, scenario_name: str, expectations: dict) -> None:
        # retriable check the expectations
        attempts = 5
        while self.__is_expected(expectations) is False:
            attempts = attempts - 1
            if attempts == 0:
                break
            time.sleep(1)

        if attempts == 0:
            raise Exception(f"{scenario_name} failed.")
        else:
            print(f"Scenario `{scenario_name}` expectation meets the health report stats.")
