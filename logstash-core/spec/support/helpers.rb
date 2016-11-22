# encoding: utf-8
def silence_warnings
  warn_level = $VERBOSE
  $VERBOSE = nil
  yield
ensure
  $VERBOSE = warn_level
end

def clear_data_dir
    data_path = agent_settings.get("path.data")
    Dir.foreach(data_path) do |f|
    next if f == "." || f == ".." || f == ".gitkeep"
    FileUtils.rm_rf(File.join(data_path, f))
  end
end

RSpec::Matchers.define :ir_eql do |expected|
  match do |actual|
    next unless expected.java_kind_of?(org.logstash.config.ir.SourceComponent) && actual.java_kind_of?(org.logstash.config.ir.SourceComponent)
    
    expected.sourceComponentEquals(actual)
  end
  
  failure_message do |actual|
    "actual value \n#{actual.to_s}\nis not .sourceComponentEquals to the expected value: \n#{expected.to_s}\n"
  end
end

SUPPORT_DIR = Pathname.new(::File.join(::File.dirname(__FILE__), "support"))
