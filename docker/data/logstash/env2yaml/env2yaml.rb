require 'yaml'

def squash_setting(setting)
  setting.downcase.gsub('.', '').gsub('_', '')
end

# Set filename
filename = ARGV[0]

# Load YAML file
settings = YAML.load_file(filename)

# Define list of valid settings
valid_settings = %w[
  api.enabled
  api.http.host
  # Add all the valid settings here...
]

# Normalize keys in valid settings
normalized_valid_settings = valid_settings.map { |setting| squash_setting(setting) }

# Prepare a hash for mapping normalized keys back to their original form
valid_setting_map = Hash[normalized_valid_settings.zip(valid_settings)]

# Merge any valid settings found in the environment
found_new_settings = false

ENV.each do |key, value|
  normalized_key = squash_setting(key)

  # If the environment variable is a valid setting, update the settings
  if valid_setting_map[normalized_key]
    found_new_settings = true
    puts "Setting '#{valid_setting_map[normalized_key]}' from environment."

    # Try to parse the value as YAML
    begin
      parsed_value = YAML.load(value)
    rescue Psych::SyntaxError
      parsed_value = value
    end

    # Handle complex structures
    keys = valid_setting_map[normalized_key].split('.')
    last_key = keys.pop
    current = settings
    keys.each { |k| current = (current[k] ||= {}) }
    current[last_key] = parsed_value
  end
end

# If new settings were found, write them back to the YAML file
if found_new_settings
  File.open(filename, 'w') {|f| f.write settings.to_yaml } 
end

