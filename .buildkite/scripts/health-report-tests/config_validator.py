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

    def __validate_keys(self, yaml_sub_keys: List[Dict[str, Any]], required_sub_keys: Dict[str, List[Any]]) -> bool:
        for required_sub_key in required_sub_keys:
            if isinstance(required_sub_key, str):
                is_key_found = False
                for yaml_sub_key in yaml_sub_keys:
                    if yaml_sub_key.get(required_sub_key):
                        is_key_found = True
                        break
                if not is_key_found:
                    print(f"Required {required_sub_key} key is not found in {yaml_sub_keys}")
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
        for yaml_key in self.yaml_content:
            if yaml_key == "name":
                continue
            if yaml_key not in required_config_keys:
                return False
            if not self.__validate_keys(self.yaml_content.get(yaml_key), self.REQUIRED_KEYS.get(yaml_key)):
                return False

        print(f"YAML config validation succeeded.")
        return True
