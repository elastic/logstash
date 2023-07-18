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

require "erb"

module LogStash module Docgen
  class IndexContext
    class PluginContext
      GITHUB_URL = "https://github.com/logstash-plugins"

      attr_reader :name, :type

      def initialize(name, type)
        @name = name
      end

      def full_name
        "logstash-#{type}-#{name}"
      end

      def description
        "WHERE I SHOULD TAKE THAT? GITHUB?"
      end

      def github_url
        "#{GITHUB_URL}/#{full_name}"
      end

      def edit_url
        "#{github_url}/lib/logstash/#{type}/#{name}.rb"
      end
    end

    attr_reader :plugins

    def initialize(type, plugins)
      @plugins = plugins.sort.collect { |plugin| PluginContext.new(plugin, type) }
    end

    def get_binding
      binding
    end
  end

  class Index
    ASCIIDOC_EXTENSION = ".asciidoc"
    PLUGIN_TYPES = %w(codecs inputs filters outputs)

    TEMPLATE_PATH = ::File.expand_path(::File.join(::File.dirname(__FILE__), "..", "..", "..", "templates"))
    TEMPLATES = {
      :inputs => ::File.read(::File.join(TEMPLATE_PATH, "index-inputs.asciidoc.erb")),
      :codecs => ::File.read(::File.join(TEMPLATE_PATH, "index-codecs.asciidoc.erb")),
      :filters => ::File.read(::File.join(TEMPLATE_PATH, "index-filters.asciidoc.erb")),
      :outputs => ::File.read(::File.join(TEMPLATE_PATH, "index-outputs.asciidoc.erb"))
    }

    attr_reader :path

    def initialize(path)
      @path = path
    end

    def generate
      PLUGIN_TYPES.each do |type|
        plugins =  logstash_files(::File.join(path, type))
            .sort
            .collect { |file| ::File.basename(file, ASCIIDOC_EXTENSION) }

        template = ERB.new(TEMPLATES[type.to_sym], trim_mode: "-")
        save(type, template.result(IndexContext.new(type, plugins).get_binding))
      end
    end

    def logstash_files(source_path)
      Dir.glob(::File.join(source_path, "*.asciidoc"))
    end

    def save(type, output)
      target = ::File.join(path, "#{type}#{ASCIIDOC_EXTENSION}")
      File.open(target, "w") { |f| f.write(output) }
    end
  end
end end
