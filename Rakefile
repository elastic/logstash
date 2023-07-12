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

$: << File.join(File.dirname(__FILE__), "lib")
$: << File.join(File.dirname(__FILE__), "logstash-core/lib")

task "default" => "help"

task "help" do
  puts <<HELP
What do you want to do?

Packaging?
  `rake artifact:tar`  to build a deployable .tar.gz
  `rake artifact:rpm`  to build an rpm
  `rake artifact:deb`  to build an deb

Developing?
  `rake bootstrap`          installs any dependencies for doing Logstash development
  `rake test:install-core`  installs any dependencies for testing Logstash core
  `rake test:core`          to run Logstash core tests
  `rake vendor:clean`       clean vendored dependencies used for Logstash development
  `rake lint:report`        to run the Rubocop linter
  `rake lint:format`        to automatically format the code
HELP
end
