import yaml
from typing import Any, List, Dict, Union


class ConfigValidator:
    REQUIRED_KEYS: Dict[str, List[Any]] = {
        "config": ["pipeline.id", "config.string"],
        "expectation": ["status", "symptom", {"diagnosis": ["cause"]},
                        {"impacts": ["description", "impact_areas"], "details": ["run_state"]}]
    }

    def __init__(self):
        self.yaml_content = None

    def __validate_keys(self, data: Dict[str, Any], required_keys: Dict[str, List[Any]]) -> bool:
        for key, required_list in required_keys.items():
            if key not in data:
                print(f"Missing top-level key: {key}")
                return False
            for item in required_list:
                if isinstance(item, str):
                    if not self.__check_nested_key(data[key], item):
                        print(f"Missing nested key: {item} in {key}")
                        return False
                elif isinstance(item, dict):
                    for sub_key, sub_value in item.items():
                        if sub_key not in data[key]:
                            print(f"Missing key: {sub_key} in {key}")
                            return False
                        # Recursively check the nested dictionary
                        if not self.__validate_keys(data[key][sub_key], {sub_key: sub_value}):
                            return False
        return True

    def __check_nested_key(self, data: Dict[str, Any], nested_key: str) -> bool:
        keys = nested_key.split('.')
        for key in keys:
            if key not in data:
                return False
        return True

    def load(self, file_path: str) -> None:
        """Load the YAML file content into self.yaml_content."""
        self.yaml_content: [Dict[str, Any]] = None
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

        if not isinstance(self.yaml_content, Dict):
            print(f"YAML structure is not as expected, it should start with a Dict.")
            return False

        required_config_keys = list(self.REQUIRED_KEYS.keys())
        for item in self.yaml_content:
            if item == "name":
                continue
            if item not in required_config_keys:
                return False

        if self.__validate_keys(self.yaml_content, self.REQUIRED_KEYS):
            print("Valid YAML content detected.")
        else:
            print("YAML validation failed.")
        return True
