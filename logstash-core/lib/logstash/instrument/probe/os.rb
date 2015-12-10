# encoding: utf-8
java_import "java.lang.management.ManagementFactory"
java_import "java.lang.management.OperatingSystemMXBean"

# Thin layer to handle the communication between ruby
# and the Java Management api.
module LogStash module Instrument module Probe
  class Jvm
  end

  class Os
    attr_reader :os_mxbean

    def initialize
      @os_mxbean = ManagementFactory.getOperatingSystemMXBean();
    end

    def available_processors
    end

    def arch
    end

    def system_load_average
      load_average = os_mxbean.getSystemLoadAverage
      return (load_average == -1) ? nil : load_average
    end

    def call(method)
    end

    ######################################
    ######################################
    ######################################
    
    def fs
      Fs.new(os_mxbean)
    end

    def memory
      Memory.new(self)
    end
    
    ######################################
    ######################################
    ######################################
    # File handle, limit?
    # File descriptor
    class Fs
      METHODS = %w(getFreePhysicalMemorySize
      getTotalPhysicalMemorySize
      getFreeSwapSpaceSize
      getTotalSwapSpaceSize)

      # Convert from a CamelCase method to an underscore version
      def self.underscore(str)
        str.gsub!(/^get/, '')
        str.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
        str.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
        str.tr!("-", "_")
        str.downcase!
        str
      end

      METHODS.each do |method|
        define_method underscore(method) do
          call(method)
        end
      end

      def initialize(os_mxbean)
        @os_mxbean = os_mxbean
      end

      # We wrap all the methods call to the underlying MxBean, for
      # two reasons:
      #
      # 1. Not all the methods are implemented by all the OS beans.
      # 2. The Java Security manager could block some of the call and raise and exception.
      #
      # I think for #2, JRuby doesn't currently support the security manager but things might
      # change in the future.
      def call(method)
        if @os_mxbean.respond_to?(method)
          result = @os_mxbean.send(method)
          return result == -1 ? nil : result
        end
        return nil
      rescue
        return nil
      end
    end

    class Memory
      def initialize(os)
      end
    end
  end
end; end; end
