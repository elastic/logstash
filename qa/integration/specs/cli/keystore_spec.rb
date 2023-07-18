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

require_relative "../../framework/fixture"
require_relative "../../framework/settings"
require_relative "../../services/logstash_service"
# require_relative "../../framework/helpers"
require "logstash/devutils/rspec/spec_helper"
require "stud/temporary"
require "fileutils"
require "open3"

describe "CLI > logstash-keystore" do
  before(:all) do
    @fixture = Fixture.new(__FILE__)
    @logstash = @fixture.get_service("logstash")
  end

  after do
    FileUtils.rm_f File.join(@logstash.logstash_home, 'config', 'logstash.keystore')
  end

  context 'create' do
    before do
      FileUtils.rm_f File.join(@logstash.logstash_home, 'config', 'logstash.keystore')
    end

    it "works" do
      env = {'LOGSTASH_KEYSTORE_PASS' => 'PaSSWD'}
      if ENV['BUILD_JAVA_HOME']
        env['LS_JAVA_HOME'] = ENV['BUILD_JAVA_HOME']
      end
      keystore_list = @logstash.run_cmd(['bin/logstash-keystore', 'create'], true, env)
      expect(keystore_list.stderr_and_stdout).to_not match(/ERROR/)
      expect(keystore_list.stderr_and_stdout).to include('Created Logstash keystore')
    end
  end

  context 'list' do
    before do
      keystore = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "fixtures", "logstash.keystore"))
      FileUtils.cp keystore, File.join(@logstash.logstash_home, 'config')
    end

    it "works" do
      env = {'LOGSTASH_KEYSTORE_PASS' => 'PaSSWD'}
      if ENV['BUILD_JAVA_HOME']
        env['LS_JAVA_HOME'] = ENV['BUILD_JAVA_HOME']
      end
      keystore_list = @logstash.run_cmd(['bin/logstash-keystore', 'list'], true, env)
      expect(keystore_list.stderr_and_stdout).to_not match(/ERROR/)
      expect(keystore_list.stderr_and_stdout).to include('foo') # contains foo: bar
    end
  end
end
