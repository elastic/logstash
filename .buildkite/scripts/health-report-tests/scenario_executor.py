"""
A class to execute the given scenario for Logstash Health Report integration test
"""
from deepdiff import DeepDiff
from logstash_health_report import LogstashHealthReport


class ScenarioExecutor:
    logstash_health_report_api = LogstashHealthReport()

    def __init__(self):
        pass

    def __is_expected(self, scenario_content: list) -> None:
        logstash_health = self.logstash_health_report_api.get()
        print(f"Logstash health report: {logstash_health}")

        differences = []
        for index, item in enumerate(scenario_content):
            if "expectation" in item:
                key = f"Item {index + 1}"
                stat_value = logstash_health.get(key, {}).get("expectation")

                if stat_value:
                    diff = DeepDiff(item["expectation"], stat_value, ignore_order=True).to_dict()
                    if diff:
                        differences.append({key: diff})
                else:
                    print(f"Stats do not contain an 'expectation' entry for {key}")

        if differences:
            print("Differences found in 'expectation' section between YAML content and stats:")
            for diff in differences:
                print(diff)
            return False
        else:
            print("YAML 'expectation' section matches the stats.")
            return True

    def on(self, scenario_name: str, scenario_content: list) -> None:
        print(f"Testing the scenario: {scenario_content}")
        if self.__is_expected(scenario_content) is False:
            raise Exception(f"{scenario_name} failed.")
