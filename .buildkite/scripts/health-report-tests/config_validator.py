import yaml
from typing import Any, List, Dict, Union


class ConfigValidator:

    REQUIRED_KEYS: Dict[str, List[str]] = {
        "config": ["pipeline.id", "config.string"],
        "expectation": ["status", "symptom", "diagnosis", "impacts", "details"],
        "diagnosis": ["cause"],
        "impacts": ["description", "impact_areas"],
        "details": ["run_state"],
    }

    def __init__(self):
        self.yaml_content = None

    def __validate_keys(self, actual_keys: List[str], expected_keys: List[str], section: str) -> bool:
        """Validate the keys at the current level."""
        missing_keys = set(expected_keys) - set(actual_keys)
        if len(missing_keys) == len(expected_keys):
            print(f"Missing keys in {section}: {missing_keys}")
            return False
        return True

    def __validate_config(self, config_list: List[Dict[str, Any]]) -> bool:
        """Validate the 'config' section."""
        for config_item in config_list:
            if not self.__validate_keys(list(config_item.keys()), self.REQUIRED_KEYS["config"], "config"):
                return False
        return True

    def __validate_expectation(self, expectation_list: List[Dict[str, Any]]) -> bool:
        """Validate the 'expectation' section."""
        for expectation_item in expectation_list:
            if not self.__validate_keys(list(expectation_item.keys()), self.REQUIRED_KEYS["expectation"], "expectation"):
                return False
            if "diagnosis" in expectation_item:
                for diagnosis in expectation_item["diagnosis"]:
                    if not self.__validate_keys(list(diagnosis.keys()), self.REQUIRED_KEYS["diagnosis"], "diagnosis"):
                        return False
            if "impacts" in expectation_item:
                for impact in expectation_item["impacts"]:
                    if not self.__validate_keys(list(impact.keys()), self.REQUIRED_KEYS["impacts"], "impacts"):
                        return False
            if "details" in expectation_item:
                for detail in expectation_item["details"]:
                    if not self.__validate_keys(list(detail.keys()), self.REQUIRED_KEYS["details"], "details"):
                        return False
        return True

    def load(self, file_path: str) -> None:
        """Load the YAML file content into self.yaml_content."""
        self.yaml_content: Union[List[Dict[str, Any]], None] = None
        try:
            with open(file_path, 'r') as file:
                self.yaml_content = yaml.safe_load(file)
        except yaml.YAMLError as exc:
            print(f"Error in YAML file: {exc}")
            self.yaml_content = None

    def is_valid(self) -> bool:
        """Validate the entire YAML structure."""
        if self.yaml_content is None:
            print(f"YAML content is empty.")
            return False

        if not isinstance(self.yaml_content, list):
            print(f"YAML structure is not as expected, it should start with a list.")
            return False

        for item in self.yaml_content:
            if "config" in item and not self.__validate_config(item["config"]):
                return False

            if "expectation" in item and not self.__validate_expectation(item["expectation"]):
                return False

        print(f"YAML file validation successful!")
        return True
