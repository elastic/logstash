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

require "logstash/config/grammar"
require "logstash/config/config_ast"
require "logger"

class LogStash::Config::File
  include Enumerable
  include LogStash::Util::Loggable

  public
  def initialize(text)
    @text = text
    @config = parse(text)
  end # def initialize

  def parse(text)
    grammar = LogStashConfigParser.new
    result = grammar.parse(text)
    if result.nil?
      raise LogStash::ConfigurationError, grammar.failure_reason
    end
    return result
  end # def parse

  def plugin(plugin_type, name, *args)
    klass = LogStash::Plugin.lookup(plugin_type, name)
    return klass.new(*args)
  end

  def each
    @config.recursive_select(LogStash::Config::AST::Plugin)
  end
end #  class LogStash::Config::Parser

#agent.config(cfg)
