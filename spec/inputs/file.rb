require "test_utils"
require "tempfile"

describe "inputs/file" do
  extend LogStash::RSpec

  @@END_OF_TEST_DATA = "byebye"

  describe "starts at the end of an existing file" do
    tmp_file = Tempfile.new('logstash-spec-input-file')

    config <<-CONFIG
      input {
        file {
          type => "blah"
          path => "#{tmp_file.path}"
          sincedb_path => "/dev/null"
        }
      }
    CONFIG

    #This first part of the file should not be read
    expected_lines = 20
    File.open(tmp_file, "w") do |f|
      expected_lines.times do |i|
        f.write("Not Expected Sample event #{i}")
        f.write("\n")
      end
    end

    input do |plugins|
      sequence = 0
      file = plugins.first
      output = Shiftback.new do |event|
        if event.message == @@END_OF_TEST_DATA
          file.teardown
          insist {sequence } == expected_lines
        else
          sequence += 1
          #Test data
          insist { event.message }.start_with?("Expected")
        end
      end
      file.register
      #Launch the input in separate thread
      thread = Thread.new(file, output) do |*args|
        file.run(output)
      end
      # Need to be sure the input is started, any idea?
      sleep(2)
      # Append to the file
      File.open(tmp_file, "a") do |f|
        expected_lines.times do |i|
          f.write("Expected Sample event #{i}")
          f.write("\n")
        end
        f.write(@@END_OF_TEST_DATA)
        f.write("\n")
      end
      thread.join
    end # input
  end

  describe "starts at the beginning of an existing file" do
    tmp_file = Tempfile.new('logstash-spec-input-file')

    config <<-CONFIG
      input {
        file {
          type => "blah"
          path => "#{tmp_file.path}"
          start_position => "beginning"
          sincedb_path => "/dev/null"
        }
      }
    CONFIG

    #This first part of the file should be read
    expected_lines = 20
    File.open(tmp_file, "w") do |f|
      expected_lines.times do |i|
        f.write("Expected Sample event #{i}")
        f.write("\n")
      end
    end

    input do |plugins|
      sequence = 0
      file = plugins.first
      output = Shiftback.new do |event|
        if event.message == @@END_OF_TEST_DATA
          file.teardown
          insist {sequence } == expected_lines*2
        else
          sequence += 1
          #Test data
          insist { event.message }.start_with?("Expected")
        end
      end
      file.register
      #Launch the input in separate thread
      thread = Thread.new(file, output) do |*args|
        file.run(output)
      end
      # Need to be sure the input is started, any idea?
      sleep(2)
      # Append to the file
      File.open(tmp_file, "a") do |f|
        expected_lines.times do |i|
          f.write("Expected Sample event #{i}")
          f.write("\n")
        end
        f.write(@@END_OF_TEST_DATA)
        f.write("\n")
      end
      thread.join
    end # input
  end

  describe "restarts at the sincedb value" do
    tmp_file = Tempfile.new('logstash-spec-input-file')
    tmp_sincedb = Tempfile.new('logstash-spec-input-file-sincedb')

    config <<-CONFIG
      input {
        file {
          type => "blah"
          path => "#{tmp_file.path}"
          start_position => "beginning"
          sincedb_path => "#{tmp_sincedb.path}"
        }
      }
    CONFIG

    #This first part of the file should NOT be read
    expected_lines = 20
    File.open(tmp_file, "w") do |f|
      expected_lines.times do |i|
        f.write("UnExpected Sample event #{i}")
        f.write("\n")
      end
    end
    #Manually write the sincedb
    stat = File::Stat.new(tmp_file)
    File.open(tmp_sincedb, "w") do |f|
      f.write("#{stat.ino} #{stat.dev_major} #{stat.dev_minor} #{stat.size}")
      f.write("\n")
    end

    input do |plugins|
      sequence = 0
      file = plugins.first
      output = Shiftback.new do |event|
        if event.message == @@END_OF_TEST_DATA
          file.teardown
          insist { sequence } == expected_lines
        else
          sequence += 1
          #Test data
          insist { event.message }.start_with?("Expected")
        end
      end
      file.register
      #Launch the input in separate thread
      thread = Thread.new(file, output) do |*args|
        file.run(output)
      end
      # Need to be sure the input is started, any idea?
      sleep(2)
      # Append to the file
      File.open(tmp_file, "a") do |f|
        expected_lines.times do |i|
          f.write("Expected SaMple event #{i}")
          f.write("\n")
        end
        f.write(@@END_OF_TEST_DATA)
        f.write("\n")
      end
      thread.join
    end # input
  end
end
