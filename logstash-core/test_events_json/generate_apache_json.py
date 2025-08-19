import json
from pathlib import Path

# Helper function to repeat a pattern until reaching a target byte size
def generate_large_field(base, repeat_str, target_size):
    result = base
    while len(result.encode('utf-8')) < target_size:
        result += repeat_str
    return result[:target_size]  # Truncate to exact size if needed

# Base JSON structure
base_json = {
    "clientip": "192.168.1.100",
    "ident": "-",
    "auth": "john_doe",
    "timestamp": "03/Jul/2025:13:45:12 +0000",
    "verb": "GET",
    "request": "",
    "http_version": "1.1",
    "response": 200,
    "bytes": 123456,
    "referrer": "http://example.com/resource",
    "agent": "",
    "headers": {
        "cookie": ""
    },
    "message": ""
}

# Estimate base JSON size
base_size = len(json.dumps(base_json, indent=2).encode('utf-8'))
target_size = 128 * 1024  # 128 KB
payload_budget = target_size - base_size
field_budget = payload_budget // 4

# Fill the large fields
base_json["request"] = generate_large_field("/index.html?", "paramX=valueX&", field_budget)
base_json["agent"] = generate_large_field("Mozilla/5.0 (", " ExtraData;", field_budget)
base_json["headers"]["cookie"] = generate_large_field("sessionid=xyz;", " cookieX=verylongvalue;", field_budget)
base_json["message"] = generate_large_field("Log line start: ", "word ", field_budget)

# Save to file
file_path = Path("apache_log_event_128kb.json")
with open(file_path, "w", encoding="utf-8") as f:
    json.dump(base_json, f, indent=2)

print(f"Saved to {file_path.resolve()} (Size: {file_path.stat().st_size} bytes)")
