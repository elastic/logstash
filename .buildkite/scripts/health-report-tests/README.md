## Description
This package for integration tests of the Health Report API.
Export `LS_BRANCH` to run on a specific branch. By default, it uses the main branch.

## How to run the Health Report Integration test?
### Prerequisites
Make sure you have python installed. Install the integration test dependencies with the following command:
```shell
python3 -mpip install -r .buildkite/scripts/health-report-tests/requirements.txt
```

### Run the integration tests
```shell
python3 .buildkite/scripts/health-report-tests/main.py
```

### Troubleshooting
- If you get `WARNING: pip is configured with locations that require TLS/SSL,...` warning message, make sure you have python >=3.12.4 installed.