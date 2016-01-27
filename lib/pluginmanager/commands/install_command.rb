# encoding: utf-8
require "pluginmanager/command"
require "bootstrap/util/compress"
require "fileutils"
require "pluginmanager/sources/http"
require "pluginmanager/sources/local"
require "stud/temporary"

class LogStash::PluginManager::InstallCommand < LogStash::PluginManager::Command

  # Relocate a set of plugins within a pack directory into the logstash cache location. This gems
  # are going to be used later on during installation time.
  # @param pack_dir [String] The location of an uncompressed packaged plugin
  def copy_packaged_gems(pack_dir)
    FileUtils.cp(Dir.glob(File.join(pack_dir, "**", "*.gem")), LogStash::Environment::CACHE_PATH)
  end

  # Check if the installtion should be made in local mode, it's based on either having the local
  # flag provided or on having packaged plugins to be installed.
  # @return [Boolean] True in case of performing a local installation
  def local?
    @local || @packs
  end

  # Find in the extracted packaged plugins the list of plugins to be installed
  # @param [String] The packaged plugin location in the file system, should be uncompressed.
  # @return [Array] The list of plugins to be installed
  def select_plugins(pack_dir)
    Dir.glob(File.join(pack_dir, "*.gem")).map do |path|
      fields = File.basename(path, ".gem").split("-")
      (fields.count > 1 ? fields[0...-1] : fields).join("-")
    end
  end

  # Fetch a package from a URI, either from a web uri or from the local file system.
  # @param [URI] The package url
  # @param [String] A temporary directy used to store the fetched package.
  # @return [String] The location of the fetched package.
  def fetch_pack(source, temp_dir)
    file, _ =  source.fetch(temp_dir)
    return file
  end

  # Extract a package of plugins
  # @param [String] The package location
  # @return [String] The location of the extracted content
  def extract_pack(file)
    filename = File.basename(file, ".zip").split("-")[0]
    output_dir = File.join(File.dirname(file), "out")
    zip.extract(file, output_dir)
    return File.join(output_dir, "logstash", filename)
  end

  def find_packs(args=[])
    packs = []
    args.clone.each do |arg|
      next if (arg.start_with?("logstash-") || File.extname(arg) == ".gem")
      source = LogStash::PluginManager::Sources.factory(arg)
      # We should not remove packages called by name that does not exist, they
      # could still be plugins to be installed from rubygems
      if !(source.is_a?(LogStash::PluginManager::Sources::HTTP) &&
          source.fallback &&
          !source.exist? )
        args.delete(arg)
      end
      packs << source
    end
    packs
  end

  # Finds and makes sure if there are packages willing to be installed they are
  # available inside the system.
  # @return [Array] The list of plugins to be installed from within the package.
  def fetch_and_copy_packs(args=[], &block)
    FileUtils.mkdir_p(LogStash::Environment::CACHE_PATH) unless args.empty?
    plugins = []
    Stud::Temporary.directory("logstash-plugin-manager") do |temp_dir|
      args.each do |arg|
        pack_dir = block.call(arg, temp_dir)
        next if pack_dir.nil? || pack_dir.empty?
        plugins << select_plugins(pack_dir)
        copy_packaged_gems(pack_dir)
      end
    end
    @packs = true if plugins.size > 0
    plugins.flatten
  end

  def verify_pack!(pack)
    puts("Validating #{pack}")
    signal_error("Installation aborted, verification failed for #{pack}, version #{pack.version}.") unless pack.valid?
  end

  def zip
    @zip ||= LogStash::Util::Zip
  end

end
