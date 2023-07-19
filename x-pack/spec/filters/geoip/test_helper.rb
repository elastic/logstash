# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require 'spec_helper'
require "digest"

module GeoipHelper
  def get_data_dir_path
    ::File.join(LogStash::SETTINGS.get_value("path.data"), "plugins", "filters", "geoip")
  end

  def get_dir_path(dirname)
    ::File.join(get_data_dir_path, dirname)
  end

  def get_file_path(dirname, filename)
    ::File.join(get_dir_path(dirname), filename)
  end

  def md5(file_path)
    ::File.exist?(file_path) ? Digest::MD5.hexdigest(::File.read(file_path)) : ''
  end

  def default_city_db_path
    ::File.join(get_data_dir_path, "CC", default_city_db_name)
  end

  def default_city_gz_path
    ::File.join(get_data_dir_path, "CC", "GeoLite2-City.tgz")
  end

  def default_asn_db_path
    ::File.join(get_data_dir_path, "CC", default_asn_db_name)
  end

  def metadata_path
    ::File.join(get_data_dir_path, "metadata.csv")
  end

  def default_city_db_name
    "GeoLite2-City.mmdb"
  end

  def default_asn_db_name
    "GeoLite2-ASN.mmdb"
  end

  def second_city_db_path
    ::File.join(get_data_dir_path, second_dirname, default_city_db_name)
  end

  def second_asn_db_path
    ::File.join(get_data_dir_path, second_dirname, default_asn_db_name)
  end

  def second_dirname
    "1582156922"
  end

  def create_default_city_gz
    ::File.open(default_city_gz_path, "w") { |f| f.write "make a non empty file" }
  end

  def default_city_db_md5
    md5(default_city_db_path)
  end

  def default_asn_db_md5
    md5(default_asn_db_path)
  end

  def write_temp_metadata(temp_file_path, row = nil)
    now = Time.now.to_i
    dirname = "CC"

    metadata = []
    metadata << ["ASN", now, "", dirname, false]
    metadata << ["City", now, "", dirname, false]
    metadata << row if row

    FileUtils.mkdir_p(::File.dirname(temp_file_path))
    CSV.open temp_file_path, 'w' do |csv|
      metadata.each { |row| csv << row }
    end
  end

  def rewrite_temp_metadata(temp_file_path, metadata = [])
    FileUtils.mkdir_p(::File.dirname(temp_file_path))
    CSV.open temp_file_path, 'w' do |csv|
      metadata.each { |row| csv << row }
    end
  end

  def city2_metadata
    ["City", Time.now.to_i, "", second_dirname, true]
  end

  def city_expired_metadata
    ["City", "1220227200", "", "1220227200", true]
  end

  def copy_city_database(filename)
    new_path = default_city_db_path.gsub(default_city_db_name, filename)
    FileUtils.cp(default_city_db_path, new_path)
  end

  def delete_file(*filepaths)
    filepaths.map { |filepath| FileUtils.rm_r(filepath) if ::File.exist?(filepath) }
  end

  def get_metadata_database_name
    ::File.exist?(metadata_path) ? ::File.read(metadata_path).split(",").last[0..-2] : nil
  end

  def copy_cc(dir_path)
    cc_database_paths = ::Dir.glob(::File.expand_path(
      ::File.join("..", "..", "..", "..", "..", "vendor", "**", "{GeoLite2-ASN,GeoLite2-City}.mmdb"),
      __FILE__))
    FileUtils.mkdir_p(dir_path)
    FileUtils.cp_r(cc_database_paths, dir_path)
  end

  def now_in_ymd
    Time.now.strftime('%Y-%m-%d')
  end

  def second_dirname_in_ymd
    Time.at(second_dirname.to_i).strftime('%Y-%m-%d')
  end
end

RSpec.configure do |c|
  c.include GeoipHelper
end
