from .fixtures import logstash
from retrying import retry
import time


def test_setting_pipeline_workers_from_environment(logstash):
    logstash.restart(args='-e pipeline.workers=6')
    assert logstash.get_node_info()['pipelines']['main']['workers'] == 6


def test_setting_pipeline_batch_size_from_environment(logstash):
    logstash.restart(args='-e pipeline.batch.size=123')
    assert logstash.get_node_info()['pipelines']['main']['batch_size'] == 123


def test_setting_pipeline_batch_delay_from_environment(logstash):
    logstash.restart(args='-e pipeline.batch.delay=36')
    assert logstash.get_node_info()['pipelines']['main']['batch_delay'] == 36


def test_setting_pipeline_unsafe_shutdown_from_environment(logstash):
    logstash.restart(args='-e pipeline.unsafe_shutdown=true')
    assert logstash.get_settings()['pipeline.unsafe_shutdown'] is True


def test_setting_pipeline_unsafe_shutdown_with_shell_style_variable(logstash):
    logstash.restart(args='-e PIPELINE_UNSAFE_SHUTDOWN=true')
    assert logstash.get_settings()['pipeline.unsafe_shutdown'] is True


def test_setting_things_with_upcased_and_underscored_env_vars(logstash):
    logstash.restart(args='-e PIPELINE_BATCH_DELAY=24')
    assert logstash.get_node_info()['pipelines']['main']['batch_delay'] == 24


def test_disabling_xpack_monitoring_via_environment(logstash):
    logstash.restart(args='-e xpack.monitoring.enabled=false')
    assert logstash.get_settings()['xpack.monitoring.enabled'] is False


def test_enabling_java_execution_via_environment(logstash):
    logstash.restart(args='-e pipeline.java_execution=true')
    logstash.assert_in_log('logstash.javapipeline')


def test_disabling_java_execution_via_environment(logstash):
    logstash.restart(args='-e pipeline.java_execution=true')
    logstash.assert_not_in_log('logstash.javapipeline')


def test_setting_elasticsearch_urls_as_an_array(logstash):
    setting_string = '["http://node1:9200","http://node2:9200"]'
    logstash.restart(args='-e xpack.monitoring.elasticsearch.hosts=%s' % setting_string)
    live_setting = logstash.get_settings()['xpack.monitoring.elasticsearch.hosts']
    assert type(live_setting) is list
    assert 'http://node1:9200' in live_setting
    assert 'http://node2:9200' in live_setting


def test_invalid_settings_in_environment_are_ignored(logstash):
    logstash.restart(args='-e cheese.ftw=true')
    assert not logstash.settings_file.contains('cheese.ftw')


def test_settings_file_is_untouched_when_no_settings_in_env(logstash):
    original_timestamp = logstash.settings_file.mtime
    original_hash = logstash.settings_file.sha256sum
    logstash.restart()
    time.sleep(1)  # since mtime() has one second resolution
    assert logstash.settings_file.mtime == original_timestamp
    assert logstash.settings_file.sha256sum == original_hash
