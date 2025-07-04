import json
from pathlib import Path

# Base CloudTrail-like event
event = {
    "eventVersion": "1.08",
    "userIdentity": {
        "type": "IAMUser",
        "principalId": "AIDACKCEVSQ6C2EXAMPLE",
        "arn": "arn:aws:iam::123456789012:user/Alice",
        "accountId": "123456789012",
        "userName": "Alice"
    },
    "eventTime": "2025-07-03T12:45:00Z",
    "eventSource": "ec2.amazonaws.com",
    "eventName": "StartInstances",
    "awsRegion": "us-west-2",
    "sourceIPAddress": "192.0.2.0",
    "userAgent": "aws-cli/2.0.0",
    "requestParameters": {
        "instancesSet": {
            "items": [
                {
                    "instanceId": "i-0123456789abcdef0"
                }
            ]
        }
    },
    "responseElements": {
        "instancesSet": {
            "items": [
                {
                    "instanceId": "i-0123456789abcdef0",
                    "currentState": {
                        "code": 0,
                        "name": "pending"
                    },
                    "previousState": {
                        "code": 80,
                        "name": "stopped"
                    }
                }
            ]
        }
    },
    "requestID": "f3c1example-bf84-45f6-90a1-example",
    "eventID": "8f91f5ad-example-4bcb-a299-example",
    "eventType": "AwsApiCall",
    "managementEvent": True,
    "recipientAccountId": "123456789012",
    "sharedEventID": "8f91f5ad-example-4bcb-a299-example",
    "additionalInfo": ""
}

# Pad to ~128 KB
target_size = 128 * 1024
base_size = len(json.dumps(event, indent=2).encode('utf-8'))
padding_size = target_size - base_size
event["additionalInfo"] = "X" * padding_size

# Write to file
file_path = Path("cloudtrail_event_128kb.json")
with open(file_path, "w", encoding="utf-8") as f:
    json.dump(event, f, indent=2)

print(f"Saved to: {file_path.resolve()} ({file_path.stat().st_size} bytes)")
