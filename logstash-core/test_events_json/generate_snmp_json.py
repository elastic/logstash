import json
from pathlib import Path

# Base SNMP-like structure
snmp_event = {
    "host": "192.0.2.5",
    "community": "public",
    "version": "2c",
    "trap_oid": "1.3.6.1.4.1.8072.2.3.0.1",
    "uptime": "132332300",
    "agent_address": "192.0.2.1",
    "enterprise_oid": "1.3.6.1.4.1.8072.3.2.10",
    "varbinds": []
}

# Create a variable binding template
varbind_template = {
    "oid": "1.3.6.1.2.1.1.1.0",
    "type": "OctetString",
    "value": "Very long SNMP variable value for testing purposes."
}

# Add many varbinds until we reach ~16KB
target_size = 128 * 1024  # 16 KB
base_size = len(json.dumps(snmp_event, indent=2).encode('utf-8'))
remaining_size = target_size - base_size
single_varbind_size = len(json.dumps(varbind_template).encode('utf-8'))

# Estimate how many varbinds to add
num_varbinds = remaining_size // single_varbind_size
snmp_event["varbinds"] = [varbind_template] * num_varbinds

# Save to file
output_path = Path("snmp_event_128kb.json")
with open(output_path, "w", encoding="utf-8") as f:
    json.dump(snmp_event, f, indent=2)

print(f"Saved to: {output_path.resolve()} ({output_path.stat().st_size} bytes)")
