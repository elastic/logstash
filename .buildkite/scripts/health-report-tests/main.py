"""
 Main entry point of the LS health report API integration test suites
"""
import os


def main():
    print(f"Hello World!")
    logstash_branch = os.environ.get("LS_BRANCH")
    if logstash_branch is None:
        print(f"LS_BRANCH is not specified, using main branch.")


if __name__ == "__main__":
    main()
