import os
import pytest
from subprocess import run, PIPE

version = run('./bin/elastic-version', stdout=PIPE).stdout.decode().strip()
version_number = version.split('-')[0]  # '7.0.0-alpha1-SNAPSHOT' -> '7.0.0'
logstash_version_string = 'logstash %s' % version_number  # eg. 'logstash 7.0.0'


try:
    if len(os.environ['STAGING_BUILD_NUM']) > 0:
        version += '-%s' % os.environ['STAGING_BUILD_NUM']  # eg. '5.3.0-d5b30bd7'
except KeyError:
    pass

container_name = 'logstash-test'
