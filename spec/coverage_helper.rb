# Useful module to help loading all logstash content when
# running coverage analysis
module CoverageHelper

  SKIP_LIST = ["lib/bootstrap/rspec.rb", "lib/logstash/util/prctl.rb"]

  def self.eager_load
    Dir.glob("lib/**/*.rb") do |file|
      next if SKIP_LIST.include?(file)
      require file
    end
  end

end
