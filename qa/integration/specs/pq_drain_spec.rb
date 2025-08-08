# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'
require_relative '../framework/helpers'
require "logstash/devutils/rspec/spec_helper"

require 'stud/temporary'

if ENV['FEATURE_FLAG'] == 'persistent_queues'
  describe "Test logstash queue draining" do
    before(:all) { @fixture = Fixture.new(__FILE__) }
    after(:all) { @fixture&.teardown }

    let(:logstash_service) { @fixture.get_service("logstash") }

    shared_examples 'pq drain' do |queue_compression_setting|
      let(:settings_flags) { super().merge('queue.drain' => true) }

      around(:each) do |example|
        Stud::Temporary.directory('data') do |tempdir|
          # expand the fixture tarball into our temp data dir
          data_dir_tarball = File.join(__dir__, '../fixtures/data_dirs/mixed-compression-queue-data-dir.tar.gz')
          `tar --directory #{Shellwords.escape(tempdir)} --strip-components 1 -xzf "#{Shellwords.escape(data_dir_tarball)}"`

          @data_dir = tempdir
          example.call
        end
      end

      around(:each) do |example|
        Stud::Temporary.file('output') do |tempfile|
          @output_file = tempfile.path
          example.call
        end
      end

      let(:pipeline) do
        <<~PIPELINE
          input { generator { count => 1 type => seed } }
          output { file { path => "#{@output_file}" codec => json_lines } }
        PIPELINE
      end

      it "reads the contents of the PQ and drains" do

        unacked_queued_elements = Pathname.new(@data_dir).glob('queue/main/checkpoint*').map { |cpf| decode_checkpoint(cpf) }
                                          .map { |cp| (cp.elements - (cp.first_unacked_seq - cp.min_sequence)) }.reduce(&:+)

        invoke_args = %W(
          --log.level=debug
          --path.settings=#{File.dirname(logstash_service.application_settings_file)}
          --path.data=#{@data_dir}
          --pipeline.workers=2
          --pipeline.batch.size=8
          --config.string=#{pipeline}
        )
        invoke_args << "-Squeue.compression=#{queue_compression_setting}" unless queue_compression_setting.nil?

        status = logstash_service.run(*invoke_args)

        aggregate_failures('process output') do
          expect(status.exit_code).to be_zero
          expect(status.stderr_and_stdout).to include("queue.type: persisted")
          expect(status.stderr_and_stdout).to include("queue.drain: true")
          expect(status.stderr_and_stdout).to include("queue.compression: #{queue_compression_setting}") unless queue_compression_setting.nil?
        end

        aggregate_failures('processing result') do
          # count the events, make sure they're all the right shape.
          expect(::File::size(@output_file)).to_not be_zero

          written_events = ::File::read(@output_file).lines.map { |line| JSON.load(line) }
          expect(written_events.size).to eq(unacked_queued_elements + 1)
          timestamps = written_events.map {|event| event['@timestamp'] }
          expect(timestamps.uniq.size).to eq(written_events.size)
        end

        aggregate_failures('resulting queue state') do
          # glob the data dir and make sure things have been cleaned up.
          # we should only have a head checkpoint and a single fully-acked page.
          checkpoints = Pathname.new(@data_dir).glob('queue/main/checkpoint*')
          expect(checkpoints.size).to eq(1)
          expect(checkpoints.first.basename.to_s).to eq('checkpoint.head')
          checkpoint = decode_checkpoint(checkpoints.first)
          expect(checkpoint.first_unacked_page).to eq(checkpoint.page_number)
          expect(checkpoint.first_unacked_seq).to eq(checkpoint.min_sequence + checkpoint.elements)

          pages = Pathname.new(@data_dir).glob('queue/main/page*')
          expect(pages.size).to eq(1)
        end
      end
    end

    context "`queue.compression` setting" do
      %w(none speed balanced size).each do |explicit_compression_setting|
        context "explicit `#{explicit_compression_setting}`" do
          include_examples 'pq drain', explicit_compression_setting
        end
      end
      context "default setting" do
        include_examples 'pq drain', nil
      end
    end
  end

  def decode_checkpoint(path)
    bytes = path.read(encoding: 'BINARY').bytes

    bstoi = -> (bs) { bs.reduce(0) {|m,b| (m<<8)+b } }

    version = bstoi[bytes.slice(0,2)]
    pagenum = bstoi[bytes.slice(2,4)]
    first_unacked_page = bstoi[bytes.slice(6,4)]
    first_unacked_seq = bstoi[bytes.slice(10,8)]
    min_sequence = bstoi[bytes.slice(18,8)]
    elements = bstoi[bytes.slice(26,4)]

    OpenStruct.new(version: version,
                   page_number: pagenum,
                   first_unacked_page: first_unacked_page,
                   first_unacked_seq: first_unacked_seq,
                   min_sequence: min_sequence,
                   elements: elements)
  end
end