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

class FilebeatService < Service
  FILEBEAT_CMD = [File.join(File.dirname(__FILE__), "../../../build", "filebeat", "filebeat"), "--strict.perms=false", "-c"]

  class BackgroundProcess
    def initialize(cmd)
      @client_out = Stud::Temporary.file
      @client_out.sync

      @process = ChildProcess.build(*cmd)
      @process.duplex = true
      @process.io.stdout = @process.io.stderr = @client_out
    end

    def start
      @process.start
      sleep(0.1)
      self
    end

    def execution_output
      @client_out.rewind

      # can be used to helper debugging when a test fails
      @execution_output = @client_out.read
    end

    def stop
      begin
        @process.poll_for_exit(5)
      rescue ChildProcess::TimeoutError
        Process.kill("KILL", @process.pid)
      end
    end
  end

  def initialize(settings)
    super("filebeat", settings)
  end

  def run(config_path)
    cmd = FILEBEAT_CMD.dup << config_path
    puts "Starting Filebeat with #{cmd.join(" ")}"
    @process = BackgroundProcess.new(cmd).start
  end

  def stop
    @process.stop
  end
end
