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

namespace "vendor" do
  task "jruby" do |task, args|
    system('./gradlew bootstrap') unless File.exist?(File.join("vendor", "jruby"))
  end # jruby

  namespace "force" do
    task "gems" => ["vendor:gems"]
  end

  task "gems", [:bundle] do |task, args|
    require "bootstrap/environment"

    if File.exist?(LogStash::Environment::LOCKFILE) # gradlew already bootstrap-ed
      puts("Skipping bundler install...")
    else
      puts("Invoking bundler install...")
      output, exception = LogStash::Bundler.invoke!(:install => true)
      puts(output)
      raise(exception) if exception
    end
  end # task gems
  task "all" => "gems"

  desc "Clean the vendored files"
  task :clean do
    rm_rf('vendor')
  end
end
