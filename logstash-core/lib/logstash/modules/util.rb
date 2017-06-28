# encoding: utf-8
require_relative "scaffold"

# This module function should be used when gems or
# x-pack defines modules in their folder structures.
module LogStash module Modules module Util
  def self.register_local_modules(path)
    STDERR.puts "-------------- register_local_modules --------------"
    modules_path = ::File.join(path, ::File::Separator, "modules")
    ::Dir.foreach(modules_path) do |item|
      # Ignore unix relative path ids
      next if item == '.' or item == '..'
      # Ignore non-directories
      next if !::File.directory?(::File.join(modules_path, ::File::Separator, item))
      LogStash::PLUGIN_REGISTRY.add(:modules, item, Scaffold.new(item, ::File.join(modules_path, ::File::Separator, item, ::File::Separator, "configuration")))
    end
  end
end end end
