import json
import os
import yaml
from pytest import config, fixture
from .constants import container_name, version
from retrying import retry
from subprocess import run, PIPE
from time import sleep

retry_settings = {
    'wait_fixed': 1000,
    'stop_max_attempt_number': 60
}


@fixture
def logstash(host):
    class Logstash:
        def __init__(self):
            self.version = version
            self.name = container_name
            self.process = host.process.get(comm='java')
            self.settings_file = host.file('/usr/share/logstash/config/logstash.yml')
            self.image_flavor = config.getoption('--image-flavor')
            self.image = 'docker.elastic.co/logstash/logstash-%s:%s' % (self.image_flavor, version)

            if 'STAGING_BUILD_NUM' in os.environ:
                self.tag = '%s-%s' % (self.version, os.environ['STAGING_BUILD_NUM'])
            else:
                self.tag = self.version

            self.docker_metadata = json.loads(
                run(['docker', 'inspect', self.image], stdout=PIPE).stdout.decode())[0]

        def start(self, args=None):
            if args:
                arg_array = args.split(' ')
            else:
                arg_array = []
            run(['docker', 'run', '-d', '--name', self.name] + arg_array + [self.image])

        def stop(self):
            run(['docker', 'kill', self.name])
            run(['docker', 'rm', self.name])

        def restart(self, args=None):
            self.stop()
            self.start(args)

        @retry(**retry_settings)
        def get_node_info(self):
            """Return the contents of Logstash's node info API.

            It retries for a while, since Logstash may still be coming up.
            Refer: https://www.elastic.co/guide/en/logstash/master/node-info-api.html
            """
            result = json.loads(host.command.check_output('curl -s http://localhost:9600/_node'))
            assert 'workers' in result['pipelines']['main']
            return result

        def get_settings(self):
            return yaml.load(self.settings_file.content_string)

        def run(self, command):
            return host.run(command)

        def stdout_of(self, command):
            return host.run(command).stdout.strip()

        def stderr_of(self, command):
            return host.run(command).stderr.strip()

        def environment(self, varname):
            environ = {}
            for line in self.run('env').stdout.strip().split("\n"):
                var, value = line.split('=')
                environ[var] = value
            return environ[varname]

        def get_docker_log(self):
            return run(['docker', 'logs', self.name], stdout=PIPE).stdout.decode()

        @retry(**retry_settings)
        def assert_in_log(self, string):
            assert string in self.get_docker_log()

        @retry(**retry_settings)
        def assert_not_in_log(self, string):
            assert string not in self.get_docker_log()

    return Logstash()
