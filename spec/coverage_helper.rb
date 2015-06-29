# Useful module to help loading all logstash content when
# running coverage analysis
module CoverageHelper

  ##
  # Skip list used to avoid loading certain patterns within
  # the logstash directories, this patterns are excluded becuause
  # of potential problems or because they are going to be loaded
  # in another way.
  ##
  SKIP_LIST = Regexp.union([
    /^lib\/bootstrap\/rspec.rb$/,
    /^lib\/logstash\/util\/prctl.rb$/,
    /^lib\/pluginmanager/
  ])

  ##
  # List of files going to be loaded directly, this files
  # are already loading their dependencies in the necessary
  # order so everything is setup properly.
  ##
  DIRECT_LOADING_MODULES = [ "lib/pluginmanager/main.rb" ]

  def self.eager_load
    Dir.glob("lib/**/*.rb") do |file|
      next if file =~ SKIP_LIST
      require file
    end
    DIRECT_LOADING_MODULES.each do |_module|
      require _module
    end
  end

end
