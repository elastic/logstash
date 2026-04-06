"""
A class to execute the given scenario for Logstash Health Report integration test
"""
import time
import re
from typing import Any
from types import MappingProxyType
from logstash_health_report import LogstashHealthReport


class ScenarioExecutor:
    logstash_health_report_api = LogstashHealthReport()

    def __init__(self):
        self.matcher = self.GrokLite()
        pass

    def __get_difference(self, expect: Any, actual: Any, path: str | None = None) -> list:

        path = path or ""
        differences = []

        match expect:
            # $include is a substring matcher
            case {"$include": inclusion} if isinstance(expect, dict) and len(expect) == 1 and isinstance(actual, str):
                if inclusion not in actual:
                    differences.append(f"Value at path `{path}` does not include:`{inclusion}`; got:`{actual}`")
            # $match is a grok-like matcher that anchors the pattern at both ends
            case {"$match": pattern_spec} if isinstance(expect, dict) and len(expect) == 1 and isinstance(actual, str):
                if not self.matcher.is_match(pattern_spec, actual):
                    differences.append(f"Value at path `{path}` does not match pattern `{pattern_spec}`; got:`{actual}`")
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

    def __is_expected(self, expectations: dict) -> bool:
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


    # GrokLite is a *LITE* implementation of Grok.
    # The idea is to allow you to use named patterns inside of regular expressions.
    # It does NOT support named captures, and mapping definitions CANNOT reference named patterns.
    class GrokLite:
        MAPPINGS = MappingProxyType({
            "ISO8601" : "[0-9]{4}-(?:0[0-9]|1[12])-(?:[0-2][0-9]|3[01])T(?:[01][0-9]|2[0-3]):(?:[0-5][0-9]):(?:[0-5][0-9])(?:[.][0-9]+)?(?:Z|[+-](?:2[0-3]|[01][0-9])(?::?[0-5][0-9])?)",
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
