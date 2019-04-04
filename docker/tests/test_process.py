from .fixtures import logstash


def test_process_is_pid_1(logstash):
    assert logstash.process.pid == 1


def test_process_is_running_as_the_correct_user(logstash):
    assert logstash.process.user == 'logstash'


def test_process_is_running_with_cgroup_override_flags(logstash):
    # REF: https://github.com/elastic/logstash-docker/pull/97
    assert '-Dls.cgroup.cpu.path.override=/' in logstash.process.args
    assert '-Dls.cgroup.cpuacct.path.override=/' in logstash.process.args
