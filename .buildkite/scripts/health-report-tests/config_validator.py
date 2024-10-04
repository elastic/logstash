import yaml
from typing import Any, List, Dict


class ConfigValidator:
    REQUIRED_KEYS = {
        "root": ["name", "config", "conditions", "expectation"],
        "config": ["pipeline.id", "config.string"],
        "conditions": ["full_start_required"],
        "expectation": ["status", "symptom", "indicators"],
        "indicators": ["pipelines"],
        "pipelines": ["status", "symptom", "indicators"],
        "DYNAMIC": ["status", "symptom", "diagnosis", "impacts", "details"],
        "details": ["status"],
        "status": ["state"]
    }

    def __init__(self):
        self.yaml_content = None

    def __has_valid_keys(self, data: any, key_path: str, repeated: bool) -> bool:
        if isinstance(data, str) or isinstance(data, bool):   # we reached values
            return True

        # we have two indicators section and for the next repeated ones, we go deeper
        first_key = next(iter(data))
        data = data[first_key] if repeated and key_path == "indicators" else data

        if isinstance(data, dict):
            # pipeline-id is a DYNAMIC
            required = self.REQUIRED_KEYS.get("DYNAMIC" if repeated and key_path == "indicators" else key_path, [])
            repeated = not repeated if key_path == "indicators" else repeated
            for key in required:
                if key not in data:
                    print(f"Missing key '{key}' in '{key_path}'")
                    return False
                else:
                    dic_keys_result = self.__has_valid_keys(data[key], key, repeated)
                    if dic_keys_result is False:
                        return False
        elif isinstance(data, list):
            for item in data:
                list_keys_result = self.__has_valid_keys(item, key_path, repeated)
                if list_keys_result is False:
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

        if not isinstance(self.yaml_content, dict):
            print(f"YAML structure is not as expected, it should start with a Dict.")
            return False

        result = self.__has_valid_keys(self.yaml_content, "root", False)
        return True if result is True else False
