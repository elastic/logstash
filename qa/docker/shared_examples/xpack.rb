shared_examples_for 'a container with xpack features' do |flavor|

  before do
    @image = find_image(flavor)
  end

  after do
    cleanup_container(@container)
  end

  describe 'when configuring xpack settings' do

    context 'when persists env var keys into logstash.yml' do
      let(:env) { %w(XPACK_MONITORING_ENABLED=false XPACK_MONITORING_ELASTICSEARCH_HOSTS=["http://node1:9200","http://node2:9200"]) }

      before do
        @container = start_container(@image, {'ENV' => env})
      end

      it 'saves keys instead actual value which will be resolved from keystore | env later' do
        settings = get_settings(@container)
        expect(settings['xpack.monitoring.enabled']).to eq("${XPACK_MONITORING_ENABLED}")
        expect(settings['xpack.monitoring.elasticsearch.hosts']).to eq("${XPACK_MONITORING_ELASTICSEARCH_HOSTS}")
      end
    end

    context 'with running with env vars' do
      let(:env) {
        [
          'XPACK_MONITORING_ENABLED=true',
          'XPACK_MONITORING_ELASTICSEARCH_HOSTS="http://node1:9200"',
          'XPACK_MANAGEMENT_ENABLED=true',
          'XPACK_MANAGEMENT_PIPELINE_ID=["*"]', # double quotes intentionally placed
          'XPACK_MANAGEMENT_ELASTICSEARCH_HOSTS=["http://node3:9200", "http://node4:9200"]'
        ]
      }

      it 'persists var keys into logstash.yml and uses their resolved actual values' do
        container = create_container(@image, {'ENV' => env})

        sleep(15) # wait for container run

        settings = get_settings(container)

        expect(settings['xpack.monitoring.enabled']).to eq("${XPACK_MONITORING_ENABLED}")
        expect(settings['xpack.monitoring.elasticsearch.hosts']).to eq("${XPACK_MONITORING_ELASTICSEARCH_HOSTS}")
        expect(settings['xpack.management.enabled']).to eq("${XPACK_MANAGEMENT_ENABLED}")
        expect(settings['xpack.management.pipeline.id']).to eq("${XPACK_MANAGEMENT_PIPELINE_ID}")
        expect(settings['xpack.management.elasticsearch.hosts']).to eq("${XPACK_MANAGEMENT_ELASTICSEARCH_HOSTS}")

        # get container logs
        container_logs = container.logs(stdout: true)

        # check if logs contain node3 & node4 values actually resolved and used
        expect(container_logs.include?('pipeline_id=>["*"]')).to be true
        # note that, we are not spinning up ES nodes, so values can be in errors or in pool update logs
        expect(container_logs.include?('http://node3:9200')).to be true
        expect(container_logs.include?('http://node4:9200')).to be true
      end
    end
  end
end
