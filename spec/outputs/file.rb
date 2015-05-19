# encoding: utf-8
require "test_utils"
require "logstash/outputs/file"
require "tempfile"
require "stud/temporary"

describe LogStash::Outputs::File do
  extend LogStash::RSpec

  describe "ship lots of events to a file" do
    event_count = 10000 + rand(500)
    tmp_file = Tempfile.new('logstash-spec-output-file')

    config <<-CONFIG
      input {
        generator {
          message => "hello world"
          count => #{event_count}
          type => "generator"
        }
      }
      output {
        file {
          path => "#{tmp_file.path}"
        }
      }
    CONFIG

    agent do
      line_num = 0
      # Now check all events for order and correctness.
      File.foreach(tmp_file) do |line|
        event = LogStash::Event.new(JSON.parse(line))
        insist {event["message"]} == "hello world"
        insist {event["sequence"]} == line_num
        line_num += 1
      end
      insist {line_num} == event_count
    end # agent
  end

  describe "ship lots of events to a file gzipped" do
    event_count = 10000 + rand(500)
    tmp_file = Tempfile.new('logstash-spec-output-file')

    config <<-CONFIG
      input {
        generator {
          message => "hello world"
          count => #{event_count}
          type => "generator"
        }
      }
      output {
        file {
          path => "#{tmp_file.path}"
          gzip => true
        }
      }
    CONFIG

    agent do
      line_num = 0
      # Now check all events for order and correctness.
      Zlib::GzipReader.open(tmp_file.path).each_line do |line|
        event = LogStash::Event.new(JSON.parse(line))
        insist {event["message"]} == "hello world"
        insist {event["sequence"]} == line_num
        line_num += 1
      end
      insist {line_num} == event_count
    end # agent
  end

  describe "#register" do
    let(:path) { '/%{name}' }
    let(:output) { LogStash::Outputs::File.new({ "path" => path }) }

    it 'doesnt allow the path to start with a dynamic string' do
      expect { output.register }.to raise_error(LogStash::ConfigurationError)
      output.teardown
    end

    context 'doesnt allow the root directory to have some dynamic part' do
      ['/a%{name}/',
       '/a %{name}/',
       '/a- %{name}/',
       '/a- %{name}'].each do |test_path|
         it "with path: #{test_path}" do
           path = test_path
           expect { output.register }.to raise_error(LogStash::ConfigurationError)
           output.teardown
         end
       end
    end

    it 'allow to have dynamic part after the file root' do
      path = '/tmp/%{name}'
      output = LogStash::Outputs::File.new({ "path" => path })
      expect { output.register }.not_to raise_error
    end
  end

  describe "receiving events" do
    context "when using an interpolated path" do
      context "when trying to write outside the files root directory" do
        let(:bad_event) do
          event = LogStash::Event.new
          event['error'] = '../uncool/directory'
          event
        end

        it 'writes the bad event in the specified error file' do
          Stud::Temporary.directory('filepath_error') do |path|
            config = { 
              "path" => "#{path}/%{error}",
              "filename_failure" => "_error"
            }

            # Trying to write outside the file root
            outside_path = "#{'../' * path.split(File::SEPARATOR).size}notcool"
            bad_event["error"] = outside_path


            output = LogStash::Outputs::File.new(config)
            output.register
            output.receive(bad_event)

            error_file = File.join(path, config["filename_failure"])

            expect(File.exist?(error_file)).to eq(true)
            output.teardown
          end
        end

        it 'doesnt decode relatives paths urlencoded' do
          Stud::Temporary.directory('filepath_error') do |path|
            encoded_once = "%2E%2E%2ftest"  # ../test
            encoded_twice = "%252E%252E%252F%252E%252E%252Ftest" # ../../test

            output = LogStash::Outputs::File.new({ "path" =>  "/#{path}/%{error}"})
            output.register

            bad_event['error'] = encoded_once
            output.receive(bad_event)

            bad_event['error'] = encoded_twice
            output.receive(bad_event)

            expect(Dir.glob(File.join(path, "*")).size).to eq(2)
            output.teardown
          end
        end

        it 'doesnt write outside the file if the path is double escaped' do
          Stud::Temporary.directory('filepath_error') do |path|
            output = LogStash::Outputs::File.new({ "path" =>  "/#{path}/%{error}"})
            output.register

            bad_event['error'] = '../..//test'
            output.receive(bad_event)

            expect(Dir.glob(File.join(path, "*")).size).to eq(1)
            output.teardown
          end
        end
      end

      context 'when trying to write inside the file root directory' do
        it 'write the event to the generated filename' do
          good_event = LogStash::Event.new
          good_event['error'] = '42.txt'

          Stud::Temporary.directory do |path|
            config = { "path" => "#{path}/%{error}" }
            output = LogStash::Outputs::File.new(config)
            output.register
            output.receive(good_event)

            good_file = File.join(path, good_event['error'])
            expect(File.exist?(good_file)).to eq(true)
            output.teardown
          end
        end

        it 'write the events to a file when some part of a folder or file is dynamic' do
          t = Time.now
          good_event = LogStash::Event.new("@timestamp" => t)

          Stud::Temporary.directory do |path|
            dynamic_path = "#{path}/failed_syslog-%{+YYYY-MM-dd}"
            expected_path = "#{path}/failed_syslog-#{t.strftime("%Y-%m-%d")}"

            config = { "path" => dynamic_path }
            output = LogStash::Outputs::File.new(config)
            output.register
            output.receive(good_event)

            expect(File.exist?(expected_path)).to eq(true)
            output.teardown
          end
        end

        it 'write the events to the generated path containing multiples fieldref' do
          t = Time.now
          good_event = LogStash::Event.new("error" => 42,
                                           "@timestamp" => t,
                                           "level" => "critical",
                                           "weird_path" => '/inside/../deep/nested')

          Stud::Temporary.directory do |path|
            dynamic_path = "#{path}/%{error}/%{level}/%{weird_path}/failed_syslog-%{+YYYY-MM-dd}"
            expected_path = "#{path}/42/critical/deep/nested/failed_syslog-#{t.strftime("%Y-%m-%d")}"

            config = { "path" => dynamic_path }

            output = LogStash::Outputs::File.new(config)
            output.register
            output.receive(good_event)

            expect(File.exist?(expected_path)).to eq(true)
            output.teardown
          end
        end

        it 'write the event to the generated filename with multiple deep' do
          good_event = LogStash::Event.new
          good_event['error'] = '/inside/errors/42.txt'

          Stud::Temporary.directory do |path|
            config = { "path" => "#{path}/%{error}" }
            output = LogStash::Outputs::File.new(config)
            output.register
            output.receive(good_event)

            good_file = File.join(path, good_event['error'])
            expect(File.exist?(good_file)).to eq(true)
            output.teardown
          end
        end
      end
    end
  end
end
