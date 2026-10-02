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
        # we expect expects to be existing in results
        for expect in expects:
            for result in results:
                if result.get('help_url') and "health-report-pipeline-status.html#" not in result.get('help_url'):
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
<<<<<<< HEAD
            print(f"Scenario `{scenario_name}` expectaion meets the health report stats.")
=======
            print(f"Scenario `{scenario_name}` expectation meets the health report stats.")


    # GrokLite is a *LITE* implementation of Grok.
    # The idea is to allow you to use named patterns inside of regular expressions.
    # It does NOT support named captures, and mapping definitions CANNOT reference named patterns.
    class GrokLite:
        MAPPINGS = MappingProxyType({
            "ISO8601" : "[0-9]{4}-(?:0[1-9]|1[0-2])-(?:[0-2][0-9]|3[01])T(?:[01][0-9]|2[0-3]):(?:[0-5][0-9]):(?:[0-5][0-9])(?:[.][0-9]+)?(?:Z|[+-](?:2[0-3]|[01][0-9])(?::?[0-5][0-9])?)",
        })

        def __init__(self):
            self.pattern_cache = {}
            pass

        def is_match(self, pattern_spec: str, value: str) -> bool:
            pattern = self.pattern_cache.get(pattern_spec)
            if pattern is None:
                replaced = re.sub(r"[{]([A-Z0-9_]+)[}]",
                                  lambda match: (self.MAPPINGS.get(match.group(1)) or match.group(0)),
                                  pattern_spec)
                pattern = re.compile(replaced)
                self.pattern_cache[pattern_spec] = pattern

            return bool(re.search(pattern, value))
>>>>>>> ab024f5 (Fix month regex in health report ISO8601 pattern (#19630))
