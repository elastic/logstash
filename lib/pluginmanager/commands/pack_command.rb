# encoding: utf-8
require "bootstrap/util/compress"
require "fileutils"

class LogStash::PluginManager::PackCommand < LogStash::PluginManager::Command
  def archive_manager
    zip? ? LogStash::Util::Zip : LogStash::Util::Tar
  end

  def file_extension
    zip? ? ".zip" : ".tar.gz"
  end
end
