# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require 'spec_helper'
require "digest"

def get_vendor_path
  ::File.expand_path("./vendor/", ::File.dirname(__FILE__))
end

def get_file_path(filename)
  ::File.join(get_vendor_path, filename)
end

def md5(file_path)
  ::File.exist?(file_path) ? Digest::MD5.hexdigest(::File.read(file_path)) : ''
end

DEFAULT_CITY_DB_PATH = get_file_path("GeoLite2-City.mmdb")
DEFAULT_CITY_GZ_PATH = get_file_path("GeoLite2-City.tgz")
DEFAULT_ASN_DB_PATH = get_file_path("GeoLite2-ASN.mmdb")
METADATA_PATH = get_file_path("metadata.csv")
DEFAULT_CITY_DB_NAME = "GeoLite2-City.mmdb"
DEFAULT_ASN_DB_NAME = "GeoLite2-ASN.mmdb"
SECOND_CITY_DB_NAME = "GeoLite2-City_20200220.mmdb"
SECOND_CITY_DB_PATH = get_file_path("GeoLite2-City_20200220.mmdb")
DEFAULT_CITY_DB_MD5 = md5(DEFAULT_CITY_DB_PATH)
DEFAULT_ASN_DB_MD5 = md5(DEFAULT_ASN_DB_PATH)


def write_temp_metadata(temp_file_path, row = nil)
  now = Time.now.to_i
  city = md5(DEFAULT_CITY_DB_PATH)
  asn = md5(DEFAULT_ASN_DB_PATH)

  metadata = []
  metadata << ["ASN",now,"",asn,DEFAULT_ASN_DB_NAME]
  metadata << ["City",now,"",city,DEFAULT_CITY_DB_NAME]
  metadata << row if row
  CSV.open temp_file_path, 'w' do |csv|
    metadata.each { |row| csv << row }
  end
end

def city2_metadata
  ["City",Time.now.to_i,"",md5(DEFAULT_CITY_DB_PATH),SECOND_CITY_DB_NAME]
end

def copy_city_database(filename)
  new_path = DEFAULT_CITY_DB_PATH.gsub(DEFAULT_CITY_DB_NAME, filename)
  FileUtils.cp(DEFAULT_CITY_DB_PATH, new_path)
end

def delete_file(*filepaths)
  filepaths.map { |filepath| ::File.delete(filepath) if ::File.exist?(filepath) }
end

def get_metadata_database_name
  ::File.exist?(METADATA_PATH) ? ::File.read(METADATA_PATH).split(",").last[0..-2] : nil
end