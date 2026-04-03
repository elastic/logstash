"""
A class to execute the given scenario for Logstash Health Report integration test
"""
import time
import re
from typing import Any
from logstash_health_report import LogstashHealthReport


class ScenarioExecutor:
    logstash_health_report_api = LogstashHealthReport()

    def __init__(self):
        pass

    def __get_difference(self, expect: Any, actual: Any, path: str | None = None) -> list:

        path = path or ""
        differences = []

        match expect:
            case {"$include": inclusion} if isinstance(expect, dict) and len(expect) == 1 and isinstance(actual, str):
                if inclusion not in actual:
                    differences.append(f"Value at path `{path}` does not include:`{inclusion}`; got:`{actual}`")
            case dict():
                if not isinstance(actual, dict):
                    differences.append(f"Structure differs at `{path}`, expected:`{expect}` got:`{actual}`")
                else:
                    for key in expect.keys():
                        differences.extend(self.__get_difference(expect.get(key), actual.get(key), f"{path}.{key}"))
            case list():
                if not isinstance(actual, list):
                    differences.append(f"Structure differs at `{path}`, expected:`{expect}` got:`{actual}`")
                else:
                    for index, (expectEntry, actualEntry) in enumerate(zip(expect, actual)):
                        differences.extend(self.__get_difference(expectEntry, actualEntry, f"{path}[{index}]"))
                    if len(actual) < len(expect):
                        differences.append(f"Missing entries at path `{path}`, expected:`{len(expect)}`, got:`{len(actual)}`")
            case _:
                if expect != actual:
                    differences.append(f"Value not match at path `{path}`; expected:`{expect}`, got:`{actual}`")

        return differences

    def __is_expected(self, expectations: dict) -> None:
        reports = self.logstash_health_report_api.get()
        differences = self.__get_difference(expect=expectations, actual=reports)
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
