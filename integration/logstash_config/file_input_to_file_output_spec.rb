# Encoding: utf-8
require_relative "../spec_helper"
require "stud/temporary"

describe "File input to File output" do
  let(:number_of_events) { IO.readlines(sample_log).size }
  let(:sample_log) { File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "sample.log")) }
  let(:output_file) { Stud::Temporary.file.path }
  let(:config) { 
<<EOS
    input {
       file {
         path => \"#{sample_log}\"
         stat_interval => 0
         start_position => \"beginning\"
         sincedb_path => \"/dev/null\"
       }
      }
    output {
      file {
        path => \"#{output_file}\"
      }
    }
EOS
  }

  before :all do
    command("bin/logstash-plugin install logstash-input-file logstash-output-file")
  end

  it "writes events to file" do
    cmd = "bin/logstash -e '#{config}'"
    launch_logstash(cmd)

    expect(File.exist?(output_file)).to eq(true)

    # on shutdown the events arent flushed to disk correctly
    # Known issue https://github.com/logstash-plugins/logstash-output-file/issues/12
    expect(IO.readlines(output_file).size).to be_between(number_of_events - 10, number_of_events).inclusive
  end
end
