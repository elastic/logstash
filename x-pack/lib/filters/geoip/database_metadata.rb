# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "logstash/util/loggable"
require_relative "util"
require "csv"
require "date"

module LogStash module Filters module Geoip class DatabaseMetadata
  include LogStash::Util::Loggable
  include LogStash::Filters::Geoip::Util

  def initialize(database_type, vendor_path)
    @vendor_path = vendor_path
    @metadata_path = get_file_path("metadata.csv")
    @database_type = database_type
  end

  public

  # csv format: database_type, update_at, gz_md5, md5, filename
  def save_timestamp(database_path)
    metadata = get_metadata(false)
    metadata << [@database_type, Time.now.to_i, md5(get_gz_name(database_path)), md5(database_path),
                 database_path.split("/").last]

    ::CSV.open @metadata_path, 'w' do |csv|
      metadata.each { |row| csv << row }
    end

    logger.debug("metadata updated", :metadata => metadata)
  end

  def get_all
    file_exist?(@metadata_path)? ::CSV.read(@metadata_path, headers: false) : Array.new
  end

  # Give rows of metadata in default database type, or empty array
  def get_metadata(match_type = true)
    get_all.select { |row| row[Column::DATABASE_TYPE].eql?(@database_type) == match_type }
  end

  # Return database path which has valid md5
  def database_path
    get_metadata.map { |metadata| [metadata, get_file_path(metadata[Column::FILENAME])] }
                .select { |metadata, path| file_exist?(path) && (md5(path) == metadata[Column::MD5]) }
                .map { |metadata, path| path }
                .last
  end

  def gz_md5
    get_metadata.map { |metadata| metadata[Column::GZ_MD5] }
                .last || ''
  end

  def updated_at
    (get_metadata.map { |metadata| metadata[Column::UPDATE_AT] }
                 .last || 0).to_i
  end

  # Return database related filenames in .mmdb .tgz
  def database_filenames
    get_all.flat_map { |metadata| [ metadata[Column::FILENAME], get_gz_name(metadata[Column::FILENAME]) ] }
  end
  
  def exist?
    file_exist?(@metadata_path)
  end

  class Column
    DATABASE_TYPE = 0
    UPDATE_AT     = 1
    GZ_MD5        = 2
    MD5           = 3
    FILENAME      = 4
  end

end end end end