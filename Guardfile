ignore %r{^ignored/path/}, %r{base\.rb}, %r{multiline\.rb}

require 'asciidoctor'
require 'erb'
require "docs/asciidocgen"

guard 'shell', :all_on_start => true do

  #Build doc from logstash
  watch(%r{^lib/logstash/filters/.+\.rb}) {|m|
    puts "change detected on #{m[0]}"
    gen = LogStashConfigAsciiDocGenerator.new
    gen.generate(m[0], {:output => 'docs/asciidoc/generated'})
  }

  #Prepare preview
  watch(%r{^docs/asciidoc/.*/.+\.asciidoc}) {|m|
    puts "building asciidoc for #{m[0]}"
    Asciidoctor.render_file(m[0], :in_place => true)
  }

end