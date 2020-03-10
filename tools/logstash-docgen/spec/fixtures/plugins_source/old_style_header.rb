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

require_relative "base"
require_relative "config_from_mixin"

# This is a new test plugins
# with multiple line.
class LogStash::Inputs::Dummy < LogStash::Inputs::Base
  config_name "dummy"

  include ConfigFromMixin

  # option 1 description
  config :option1, :type => :boolean, :default => false

  # option 2 description
  config :option2, :type => :string, :default => "localhost"
end
