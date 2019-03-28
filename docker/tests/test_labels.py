from .fixtures import logstash


def test_labels(logstash):
    labels = logstash.docker_metadata['Config']['Labels']
    assert labels['org.label-schema.name'] == 'logstash'
    assert labels['org.label-schema.schema-version'] == '1.0'
    assert labels['org.label-schema.url'] == 'https://www.elastic.co/products/logstash'
    assert labels['org.label-schema.vcs-url'] == 'https://github.com/elastic/logstash-docker'
    assert labels['org.label-schema.vendor'] == 'Elastic'
    assert labels['org.label-schema.version'] == logstash.tag
    if logstash.image_flavor == 'oss':
        assert labels['license'] == 'Apache-2.0'
    else:
        assert labels['license'] == 'Elastic License'
