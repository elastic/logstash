# encoding: UTF-8
require "spec_helper"
require "logstash/outputs/file"
require "logstash/event"
require "logstash/json"
require "stud/temporary"

describe LogStash::Outputs::File do
  describe "ship lots of events to a file" do
    Stud::Temporary.file('logstash-spec-output-file') do |tmp_file|
      event_count = 10000 + rand(500)

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
        tmp_file.each_line do |line|
        # File.foreach(tmp_file) do |line|
          event = LogStash::Event.new(LogStash::Json.load(line))
          insist {event["message"]} == "hello world"
          insist {event["sequence"]} == line_num
          line_num += 1
        end
        insist {line_num} == event_count
      end # agent
    end
  end

  describe "ship lots of events to a file gzipped" do
    Stud::Temporary.file('logstash-spec-output-file') do |tmp_file|
      event_count = 10000 + rand(500)

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
          event = LogStash::Event.new(LogStash::Json.load(line))
          insist {event["message"]} == "hello world"
          insist {event["sequence"]} == line_num
          line_num += 1
        end
        insist {line_num} == event_count
      end # agent
    end
  end

  describe "receiving events" do
    context "when using an interpolated path" do
      it 'permits to write inside the file root of the defined path' do
        event = LogStash::Event.new('@metadata' => { "name" => 'application', 'error' => )
      end
    end
  end

  # describe '#generate_filepath' do
  #   let(:event) do
  #     event = LogStash::Event.new

  #     event["name"] = "name"
  #     event["type"] = "awesome"

  #     event
  #   end

  #   it 'uses the event data to generated the path' do
  #     path = '/tmp/%{type}/%{name}'

  #     output = LogStash::Outputs::File.new({ "path" => path })
      
  #     expect(output.generate_filepath(event)).to eq('/tmp/awesome/name')
  #   end

  #   it 'ignores relative path' do
  #     path = '/tmp/%{type}/%{name}/%{relative}/'
  #     event[:relative] = '../aaa/'

  #     output = LogStash::Outputs::File.new({ "path" => path })
      
  #     expect(output.generate_filepath(event)).to eq('/tmp/awesome/name/relative')
  #   end
  # end

#   describe '#extract_file_root' do
#     context 'with interpolated strings in the path' do
#       it 'extracts the file root from the default path' do
#         path = '/tmp/%{type}/%{name}.txt'

#         output = LogStash::Outputs::File.new({ "path" => path })
#         expect(output.extract_file_root().to_s).to eq('/tmp')
#       end

#       it 'extracts to the file root down to the last concrete directory' do
#         path = '/tmp/down/%{type}/%{name}.txt'

#         output = LogStash::Outputs::File.new({ "path" => path })
#         expect(output.extract_file_root.to_s).to eq('/tmp/down')
#       end
#     end
    
#     context "without interpolated strings" do
#       it 'extracts the full path as the file root' do
#         path = '/tmp/down/log.txt'

#         output = LogStash::Outputs::File.new({ "path" => path })
#         expect(output.extract_file_root.to_s).to eq(path)
#       end
#     end
#   end

#   describe '#inside_file_root?' do
#     context 'when we follow relative paths' do
#       let(:path) { '/tmp/%{type}/%{name}.txt' }

#       it 'returns false if the target file is outside the file root' do
#         output = LogStash::Outputs::File.new({ 'path' => path })
#         output.register
#         expect(output.inside_file_root?('/tmp/../etc/eviluser/2004.txt')).to eq(false)
#       end

#       it 'returns true if the target file is inside the file root' do
#         output = LogStash::Outputs::File.new({ 'path' => path })
#         output.register
#         expect(output.inside_file_root?('/tmp/not/../etc/eviluser/2004.txt')).to eq(true)
#       end

#       it 'returns true if the target file is inside the file root' do
#         Stud::Temporary.file('logstash-spec-output-file') do |tmp_file|
#           output = LogStash::Outputs::File.new({ 'path' => tmp_file.path })
#           output.register
#           expect(output.inside_file_root?(tmp_file.path)).to eq(true)
#         end
#       end
#     end
#   end
end
