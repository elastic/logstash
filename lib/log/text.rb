#!/usr/bin/ruby

require 'rubygems'
require 'fileutils'
require 'json'
require 'lib/log'
require 'time'

class TextLog < Log
  def initialize(config_params)
    config = config_params.clone
    required_keys = [:name, :grok_pattern]
    optional_keys = [:attrs, :entry_print_format, :index, :sort_keys,
                     :recommended_group_by, :date_key, :date_format]
    check_hash_keys(config, required_keys, optional_keys)

    config[:import_type] = "text"
    config[:entry_print_format] ||= "@LINE"
    @grok_pattern = config.delete(:grok_pattern)
    @date_key = config.delete(:date_key)
    @date_format = config.delete(:date_format)

    @grok = nil
    @config = config
    super(config)
  end

  def parse_entry(raw_entry)
    if not @grok
      setup_grok
    end
    @grok.puts raw_entry

    res = nil
    while line = @grok.readline
      break if line[0..2] == "EOM"
      res = JSON.parse(line)
    end
    return nil unless res

    # We're parsing GROK output, and there are three kinds of outputs:
    #  @FOO - meta output from grok. We only want @LINE.
    #  QUOTEDSTRING:bar - matched pattern QUOTEDSTRING, var named bar, keep
    #  DATA - matched pattern DATA, but no variable name, so we ditch it
    res.keys.each do |key|
      if key =~ /^.+:(.+)$/
        res[$1] = res[key]
      end

      # special exception for @LINE
      if key != "@LINE"
        res.delete(key)
      end
    end

    return fix_date(res)
  end

  private
  def setup_grok
    # TODO: switch to ruby cgrok bindings from jls
    tmpd = "/tmp/grok.#{@config[:name]}.working"
    FileUtils.mkdir_p(tmpd)
    FileUtils.cp "grok-patterns", "#{tmpd}/grok-patterns"
    Dir.chdir(tmpd)
    File.open("grok.conf", "w") { |f| f.write grok_conf }
    @grok = IO.popen("/home/petef/bin/grok", "r+")
  end

  def grok_conf
    conf = []
    conf << "program {"
    conf << "  load-patterns: \"grok-patterns\""
    conf << "  file \"/dev/stdin\""
    conf << "  match {"
    conf << "    pattern: \"#{@grok_pattern}\""
    conf << "    shell: \"stdout\""
    conf << "    reaction: \"\%{@JSON}\""
    conf << "    flush: yes"
    conf << "  }"
    conf << "  match {"
    conf << "    pattern: \".?\""
    conf << "    shell: \"stdout\""
    conf << "    reaction: \"EOM\""
    conf << "    flush: yes"
    conf << "  }"
    conf << "}"

    return conf.join("\n") + "\n"
  end
end
