# encoding: utf-8
module Paquet
  class ShellUi
    def debug(message)
      report_message(:debug, message) if debug?
    end

    def info(message)
      report_message(:info, message)
    end

    def report_message(level, message)
      puts "[#{level.upcase}]: #{message}"
    end

    def debug?
      ENV["DEBUG"]
    end
  end

  def self.ui
    @logger ||= ShellUi.new
  end
end
