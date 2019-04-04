from .fixtures import logstash
import pytest


@pytest.mark.xfail
def test_whitespace_in_config_string_cli_flag(logstash):
    config = 'input{heartbeat{}}    output{stdout{}}'
    assert logstash.run("-t -e '%s'" % config).rc == 0


def test_running_an_arbitrary_command(logstash):
    result = logstash.run('uname --all')
    assert result.rc == 0
    assert 'GNU/Linux' in str(result.stdout)
