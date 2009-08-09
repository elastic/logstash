require 'rubygems'
require 'date'
require 'fileutils'
require 'json'
require 'time'

class LogException < StandardError
end

class LogNotImplementedException < StandardError
end

class Log
  attr_accessor :attrs

  def initialize(config)
    required_keys = [:name, :import_type]
    optional_keys = [:attrs, :entry_print_format, :index, :sort_keys,
                     :recommended_group_by]
    check_hash_keys(config, required_keys, optional_keys)

    @attrs = {"log:name" => config[:name],
              "log:import_type" => config[:import_type]}
    if config[:attrs]
      if not config[:attrs].is_a?(Hash)
        throw LogException.new(":attrs must be a hash")
      end

      config[:attrs].keys.each do |key|
        next unless key.to_s[0..3] == "log:"
        throw LogException.new(":attrs keys must not begin with log: (#{key})")
      end

      @attrs.merge!(config[:attrs])
    end
  end

  # passed a string that represents an "entry" in :import_type
  def import_entry(entry)
    throw LogNotImplementedException.new
  end

  def index_dir
    return "#{ENV["HOME"]}/logstash/indexes/#{@attrs["log:name"]}"
  end

  def fix_date(res)
    time = nil
    if @date_key and res[@date_key]
      raw_date = res[@date_key]
      time = nil
      begin
        time = DateTime.strptime(raw_date, @date_format)
      rescue ArgumentError
        # time didn't parse
        time = DateTime.now
      end
    end
    time ||= DateTime.now
    res["@DATE"] = time.strftime("%s")

    return res
  end

  private
  def check_hash_keys(hash, required_keys, optional_keys)
    required_keys.each do |key|
      next if hash.keys.member?(key)
      raise LogException.new("missing required key #{key}")
    end

    hash.keys.each do |key|
      next if required_keys.member?(key)
      next if optional_keys.member?(key)
      raise LogException.new("unknown key #{key}")
    end
  end
end
