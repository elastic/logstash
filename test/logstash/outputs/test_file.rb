require "rubygems"
require File.join(File.dirname(__FILE__), "..", "minitest")

require "logstash/loadlibs"
require "logstash/testcase"
require "logstash/agent"
require "logstash/logging"
require "logstash/outputs/file"

require "tmpdir"

describe LogStash::Outputs::File do
  before do
    @testdir = Dir.mktmpdir("logstash-test-output-file")
  end # before

  after do
    @output.teardown
    FileUtils.rm_r(@testdir)
  end # after

  test "basic file output" do
    test_file = File.join(@testdir, "out")
    @output = LogStash::Outputs::File.new({
      "flush_interval" => [0],
      "type" => ["foo"],
      "path" => [test_file],
      "message_format" => ["%{@message}/%{@source}"],
    })
    @output.register

    expected_output = ""
    1.upto(3) do |n|
      @output.receive(LogStash::Event.new("@message" => "line #{n}",
                                          "@source" => "test",
                                          "@type" => "foo"))
      expected_output += "line #{n}/test\n"
    end # 1.upto(3)

    assert_equal(true, File.exists?(test_file))
    file_contents = File.read(test_file)
    assert_equal(expected_output, file_contents)
  end # basic file output

  test "file appending" do
    test_file = File.join(@testdir, "out")
    expected_output = ""
    File.open(test_file, "w") do |file|
      file.write("initial data\n")
      expected_output += "initial data\n"
    end

    @output = LogStash::Outputs::File.new({
      "flush_interval" => [0],
      "type" => ["foo"],
      "path" => [test_file],
      "message_format" => ["%{@message}/%{@source}"],
    })
    @output.register

    1.upto(3) do |n|
      @output.receive(LogStash::Event.new("@message" => "line #{n}",
                                          "@source" => "test",
                                          "@type" => "foo"))
      expected_output += "line #{n}/test\n"
    end # 1.upto(3)

    file_contents = File.read(test_file)
    assert_equal(expected_output, file_contents)
  end # file appending

  test "writing to a fifo" do
    test_file = File.join(@testdir, "out")
    res = Kernel.system("mkfifo", test_file)
    assert_equal(true, res)

    @output = LogStash::Outputs::File.new({
      "flush_interval" => [0],
      "type" => ["foo"],
      "path" => [test_file],
      "message_format" => ["%{@message}"],
    })
    @output.register
    skip("Blocks with no reader on the fifo")
    # put the write in a different thread, because it will
    # block with no reader on the fifo.
    Thread.new do
      @output.receive(LogStash::Event.new("@message" => "z",
                                          "@source" => "test",
                                          "@type" => "foo"))
    end
    expected_output = "z\n"

    file_contents = ""
    File.open(test_file) do |fifo|
      file_contents = fifo.readline
    end
    assert_equal(expected_output, file_contents)
  end # writing to a fifo
end # testing for LogStash::Outputs::File
