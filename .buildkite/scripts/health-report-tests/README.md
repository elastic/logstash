## Description
This package for integration tests of the Health Report API.
Export `LS_VERSION` (major and minor version such as 8.x) to run on a specific branch. By default, it uses the main branch.

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