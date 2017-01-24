require 'yaml'
VERSION_FILE = File.expand_path(File.join("..", "..", "..", "versions.yml"), __FILE__)
version = YAML.load_file(VERSION_FILE)
