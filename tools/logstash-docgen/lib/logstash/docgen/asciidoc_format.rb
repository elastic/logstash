# encoding: utf-8
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
      ERB.new(::File.read(file), nil, "-")
    end

    def post_process!(context, erb)
      POST_PROCESS_KEYS.each do |expression, method_call|
        erb.gsub!(expression, context.send(method_call))
      end
    end
  end
end end
