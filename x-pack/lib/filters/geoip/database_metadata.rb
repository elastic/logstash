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

  def initialize
    @metadata_path = ::File.join(get_data_dir_path, "metadata.csv")
  end

  public

  # csv format: database_type, check_at, gz_md5, dirname, is_eula
  def save_metadata(database_type, dirname, is_eula)
    metadata = get_metadata(database_type, false)
    metadata << [database_type, Time.now.to_i, md5(get_gz_path(database_type, dirname)),
                 dirname, is_eula]
    update(metadata)
  end

  def update_timestamp(database_type)
    update_each_row do |row|
      row[Column::CHECK_AT] = Time.now.to_i if row[Column::DATABASE_TYPE].eql?(database_type)
      row
    end
  end

  def reset_md5(database_type)
    update_each_row do |row|
      row[Column::GZ_MD5] = ""  if row[Column::DATABASE_TYPE].eql?(database_type)
      row
    end
  end

  def update_each_row(&block)
    metadata = get_all.map do |row|
      yield row
    end
    update(metadata)
  end

  def update(metadata)
    metadata = metadata.sort_by { |row| row[Column::DATABASE_TYPE] }
    ::CSV.open @metadata_path, 'w' do |csv|
      metadata.each { |row| csv << row }
    end
    logger.trace("metadata updated", :metadata => metadata)
  end

  def get_all
    file_exist?(@metadata_path)? ::CSV.read(@metadata_path, headers: false) : Array.new
  end

  # Give rows of metadata that match/exclude the type
  def get_metadata(database_type, match = true)
    get_all.select { |row| row[Column::DATABASE_TYPE].eql?(database_type) == match }
  end

  # Return a valid database path
  def database_path(database_type)
    get_metadata(database_type).map { |metadata| get_db_path(database_type, metadata[Column::DIRNAME]) }
                .select { |path| file_exist?(path) }
                .last
  end

  def gz_md5(database_type)
    get_metadata(database_type).map { |metadata| metadata[Column::GZ_MD5] }
                .last || ''
  end

  def check_at(database_type)
    (get_metadata(database_type).map { |metadata| metadata[Column::CHECK_AT] }
                 .last || 0).to_i
  end

  def is_eula(database_type)
    (get_metadata(database_type).map { |metadata| metadata[Column::IS_EULA] }
                 .last || 'false') == 'true'
  end

  # Return all dirname
  def dirnames
    get_all.map { |metadata| metadata[Column::DIRNAME] }
  end
  
  def exist?
    file_exist?(@metadata_path)
  end

  class Column
    DATABASE_TYPE = 0
    CHECK_AT      = 1
    GZ_MD5        = 2
    DIRNAME       = 3
    IS_EULA       = 4
  end

end end end end