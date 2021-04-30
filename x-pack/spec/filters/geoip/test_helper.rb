# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require 'spec_helper'
require "digest"

module GeoipHelper
  def get_vendor_path
    ::File.expand_path("vendor", ::File.dirname(__FILE__))
  end

  def get_data_path
    ::File.join(LogStash::SETTINGS.get_value("path.data"), "plugins", "filters", "geoip")
  end

  def get_file_path(filename)
    ::File.join(get_data_path, filename)
  end

  def md5(file_path)
    ::File.exist?(file_path) ? Digest::MD5.hexdigest(::File.read(file_path)) : ''
  end

  def default_city_db_path
    get_file_path("GeoLite2-City.mmdb")
  end

  def default_city_gz_path
    get_file_path("GeoLite2-City.tgz")

  end

  def default_asn_db_path
    get_file_path("GeoLite2-ASN.mmdb")
  end

  def metadata_path
    get_file_path("metadata.csv")
  end

  def default_city_db_name
    "GeoLite2-City.mmdb"
  end

  def default_asn_db_name
    "GeoLite2-ASN.mmdb"
  end

  def second_city_db_name
    "GeoLite2-City_20200220.mmdb"
  end

  def second_city_db_path
    get_file_path("GeoLite2-City_20200220.mmdb")
  end

  def default_city_db_md5
    md5(default_city_db_path)
  end

  def DEFAULT_ASN_DB_MD5
    md5(default_asn_db_path)
  end


  def write_temp_metadata(temp_file_path, row = nil)
    now = Time.now.to_i
    city = md5(default_city_db_path)
    asn = md5(default_asn_db_path)

    metadata = []
    metadata << ["ASN",now,"",asn,default_asn_db_name]
    metadata << ["City",now,"",city,default_city_db_name]
    metadata << row if row
    CSV.open temp_file_path, 'w' do |csv|
      metadata.each { |row| csv << row }
    end
  end

  def city2_metadata
    ["City",Time.now.to_i,"",md5(default_city_db_path),second_city_db_name]
  end

  def copy_city_database(filename)
    new_path = default_city_db_path.gsub(default_city_db_name, filename)
    FileUtils.cp(default_city_db_path, new_path)
  end

  def delete_file(*filepaths)
    filepaths.map { |filepath| ::File.delete(filepath) if ::File.exist?(filepath) }
  end

  def get_metadata_database_name
    ::File.exist?(metadata_path) ? ::File.read(metadata_path).split(",").last[0..-2] : nil
  end
end

RSpec.configure do |c|
  c.include GeoipHelper
end