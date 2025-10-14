import os
import requests
import subprocess
from requests.adapters import HTTPAdapter, Retry


def call_url_with_retry(url: str, max_retries: int = 5, delay: int = 1) -> requests.Response:
    f"""
    Calls the given {url} with maximum of {max_retries} retries with {delay} delay.
    """
    schema = "https://" if "https://" in url else "http://"
    session = requests.Session()
    # retry on most common failures such as connection timeout(408), etc...
    retries = Retry(total=max_retries, backoff_factor=delay, status_forcelist=[408, 502, 503, 504])
    session.mount(schema, HTTPAdapter(max_retries=retries))
    return session.get(url)


def git_check_out_branch(branch_name: str) -> None:
    f"""
    Checks out specified branch or fails with error if checkout operation fails.
    """
    run_or_raise_error(["git", "checkout", branch_name],
                       "Error occurred while checking out the " + branch_name + " branch")


def run_or_raise_error(commands: list, error_message):
    f"""
    Executes the {list} commands and raises an {Exception} if operation fails.
    """
    result = subprocess.run(commands, env=os.environ.copy(), universal_newlines=True, stdout=subprocess.PIPE)
    if result.returncode != 0:
        full_error_message = (error_message + ", output: " + result.stdout) \
            if result.stdout else error_message
        raise Exception(f"{full_error_message}")
    print(result.stdout)

