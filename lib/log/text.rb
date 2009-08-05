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

  def destroy
    teardown_grok
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

    # rename 'FOO:bar' keys to just 'bar'
    res.keys.each do |key|
      next unless key =~ /^.+:(.+)$/
      res[$1] = res[key]
      res.delete(key)
    end

    # extra keys from grok we don't need
    res.delete("@MATCH")

    fix_date(res)

    return res
  end

  private
  def setup_grok
    #tmpd = Dir.mkdtemp("/tmp/grok.XXXXXXXX")
    ## mkdtemp is busted on my work system?
    tmpd = "/tmp/grok.#{@config[:name]}.working"
    FileUtils.mkdir_p(tmpd)
    FileUtils.cp "grok-patterns", "#{tmpd}/grok-patterns"
    Dir.chdir(tmpd)
    File.open("grok.conf", "w") { |f| f.write grok_conf }
    @grok = IO.popen("/home/petef/bin/grok", "r+")
  end

  def teardown_grok
    @grok.close
    FileUtils.rm_r(Dir.pwd)
    Dir.chdir("/")
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
