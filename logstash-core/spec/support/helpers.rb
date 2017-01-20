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

def mock_settings(settings_values)
  settings = LogStash::SETTINGS.clone

  settings_values.each do |key, value|
    settings.set(key, value)
  end

  settings
end
