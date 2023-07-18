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

require "asciidoctor"
require "erb"

module LogStash module Docgen
  class AsciidocFormat
    TEMPLATE_PATH = ::File.join(::File.dirname(__FILE__), "..", "..", "..", "templates")
    TEMPLATE_FILE = ::File.join(TEMPLATE_PATH, "plugin-doc.asciidoc.erb")
    CSS_FILE = ::File.join(TEMPLATE_PATH, "plugin-doc.css")

    POST_PROCESS_KEYS = {
      /%PLUGIN%/ => :config_name
    }

    def initialize(options = {})
      @options = options
      @template = read_template(TEMPLATE_FILE)
    end

    def generate(context)
      erb = @template.result(context.get_binding)
      post_process!(context, erb)

      if @options.fetch(:raw, true)
        erb
      else
        Asciidoctor.convert(erb,
                            :header_footer => true,
                            :stylesheet => CSS_FILE,
                            :safe => 'safe')
      end
    end

    def extension
      "asciidoc"
    end

    private
    def read_template(file)
      ERB.new(::File.read(file), trim_mode: "-")
    end

    def post_process!(context, erb)
      POST_PROCESS_KEYS.each do |expression, method_call|
        erb.gsub!(expression, context.send(method_call))
      end
    end
  end
end end
