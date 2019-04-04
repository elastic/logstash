from .fixtures import logstash
from .constants import logstash_version_string


def test_logstash_is_the_correct_version(logstash):
    assert logstash_version_string in logstash.stdout_of('logstash --version')


def test_the_default_user_is_logstash(logstash):
    assert logstash.stdout_of('whoami') == 'logstash'


def test_that_the_user_home_directory_is_usr_share_logstash(logstash):
    assert logstash.environment('HOME') == '/usr/share/logstash'


def test_locale_variables_are_set_correctly(logstash):
    assert logstash.environment('LANG') == 'en_US.UTF-8'
    assert logstash.environment('LC_ALL') == 'en_US.UTF-8'


def test_opt_logstash_is_a_symlink_to_usr_share_logstash(logstash):
    assert logstash.stdout_of('realpath /opt/logstash') == '/usr/share/logstash'


def test_all_logstash_files_are_owned_by_logstash(logstash):
    assert logstash.stdout_of('find /usr/share/logstash ! -user logstash') == ''


def test_logstash_user_is_uid_1000(logstash):
    assert logstash.stdout_of('id -u logstash') == '1000'


def test_logstash_user_is_gid_1000(logstash):
    assert logstash.stdout_of('id -g logstash') == '1000'


def test_logging_config_does_not_log_to_files(logstash):
    assert logstash.stdout_of('grep RollingFile /logstash/config/log4j2.properties') == ''


# REF: https://docs.openshift.com/container-platform/3.5/creating_images/guidelines.html
def test_all_files_in_logstash_directory_are_gid_zero(logstash):
    bad_files = logstash.stdout_of('find /usr/share/logstash ! -gid 0').split()
    assert len(bad_files) is 0


def test_all_directories_in_logstash_directory_are_setgid(logstash):
    bad_dirs = logstash.stdout_of('find /usr/share/logstash -type d ! -perm /g+s').split()
    assert len(bad_dirs) is 0
