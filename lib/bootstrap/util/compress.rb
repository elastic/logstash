# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require "zip"
require "rubygems/package"
require "fileutils"
require "zlib"
require "stud/temporary"
require "pathname"

module LogStash
  class CompressError < StandardError; end

  module Util
    module Zip
      extend self

      # Extract a zip file into a destination directory.
      # @param source [String] The location of the file to extract
      # @param target [String] Where you do want the file to be extracted
      # @raise [IOError] If the target directory already exist
      def extract(source, target, pattern = nil)
        raise CompressError.new("Directory #{target} exist") if ::File.exist?(target)
        ::Zip::File.open(source) do |zip_file|
          zip_file.each do |file|
            LogStash::Util.verify_name_safe!(file.name)
            path = ::File.join(target, file.name)
            FileUtils.mkdir_p(::File.dirname(path))
            zip_file.extract(file, path) if pattern.nil? || pattern =~ file.name
          end
        end
      end

      # Compress a directory into a zip file
      # @param dir [String] The directory to be compressed
      # @param target [String] Destination to save the generated file
      # @raise [IOError] If the target file already exist
      def compress(dir, target)
        raise CompressError.new("File #{target} exist") if ::File.exist?(target)
        ::Zip::File.open(target, ::Zip::File::CREATE) do |zipfile|
          Dir.glob("#{dir}/**/*").each do |file|
            path_in_zip = file.gsub("#{dir}/", "")
            zipfile.add(path_in_zip, file)
          end
        end
      end
    end

    module Tar
      extend self

      # Extract a tar.gz file into a destination directory.
      # @param source [String] The location of the file to extract
      # @param target [String] Where you do want the file to be extracted
      # @raise [IOError] If the target directory already exist
      def extract(file, target)
        raise CompressError.new("Directory #{target} exist") if ::File.exist?(target)

        FileUtils.mkdir(target)
        Zlib::GzipReader.open(file) do |gzip_file|
          ::Gem::Package::TarReader.new(gzip_file) do |tar_file|
            tar_file.each do |entry|
              LogStash::Util.verify_name_safe!(entry.full_name)
              LogStash::Util.verify_tar_link_entry!(entry)
              target_path = ::File.join(target, entry.full_name)

              if entry.directory?
                FileUtils.mkdir_p(target_path)
              else # is a file to be extracted (symlinks rejected in verify_tar_link_entry!)
                ::File.open(target_path, "wb") { |f| f.write(entry.read) }
              end
            end
          end
        end
      end

      # Compress a directory into a tar.gz file
      # @param dir [String] The directory to be compressed
      # @param target [String] Destination to save the generated file
      # @raise [IOError] If the target file already exist
      def compress(dir, target)
        raise CompressError.new("File #{target} exist") if ::File.exist?(target)

        Stud::Temporary.file do |tar_file|
          ::Gem::Package::TarWriter.new(tar_file) do |tar|
            Dir.glob("#{dir}/**/*").each do |file|
              name = file.gsub("#{dir}/", "")
              stats = ::File.stat(file)
              mode  = stats.mode

              if ::File.directory?(file)
                tar.mkdir(name, mode)
              else # is a file to be added
                tar.add_file(name, mode) do |out|
                  File.open(file, "rb") do |fd|
                    chunk = nil
                    size = 0
                    size += out.write(chunk) while chunk = fd.read(16384)
                    if stats.size != size
                      raise "Failure to write the entire file (#{path}) to the tarball. Expected to write #{stats.size} bytes; actually write #{size}"
                    end
                  end
                end
              end
            end
          end

          tar_file.rewind
          gzip(target, tar_file)
        end
      end

      # Compress a file using gzip
      # @param path [String] The location to be compressed
      # @param target_file [String] Destination of the generated file
      def gzip(path, target_file)
        ::File.open(path, "wb") do |file|
          gzip_file = ::Zlib::GzipWriter.new(file)
          gzip_file.write(target_file.read)
          gzip_file.close
        end
      end
    end

    # Verifies a path string is safe for zip or tar entry names (relative, no `..` traversal).
    # @param name [String] archive entry path (e.g. Zip entry name or tar full_name)
    # @raise [CompressError] if name is nil, empty, absolute, or traverses with `..`
    def self.verify_name_safe!(name)
      if name.nil? || name.to_s.strip.empty?
        raise CompressError.new("Refusing to extract file to unsafe path. Path cannot be nil or empty.")
      end
      cleanpath = Pathname.new(name).cleanpath
      if cleanpath.absolute?
        raise CompressError.new("Refusing to extract file to unsafe path: #{name}. Absolute paths are not allowed.")
      end
      if cleanpath.each_filename.to_a.include?("..")
        raise CompressError.new("Refusing to extract file to unsafe path: #{name}. Files may not traverse with `..`")
      end
    end

    # Tar.gz-only: rejects symlink entries
    # @param entry [Gem::Package::TarReader::Entry]
    # @raise [CompressError] if entry is a symlink or path is unsafe
    def self.verify_tar_link_entry!(entry)
      if entry.symlink?
        raise CompressError.new("Refusing to extract symlink entry: #{entry.full_name}")
      end
    end
    #private :verify_tar_link_entry!
  end
end
