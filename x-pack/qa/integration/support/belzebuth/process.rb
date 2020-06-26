module Belzebuth
  class Process
    def run
      Bundler.with_clean_env do
        child_process = Response.new(ChildProcess.new(*Shellwords.split(@command)))
        child_process.cwd = @options[:directory]
        child_process.environment.merge!(@options[:environment])
        child_process.io.stdout = create_tempfile("stdout")
        child_process.io.stderr = create_tempfile("stderr")

        started_at = Time.now

        child_process.start
        @wait_condition.start(child_process)

        while !@wait_condition.call(child_process)
          sleep(@wait_condition.sleep_time_between_condition(child_process))

          if can_timeout? && Time.now - started_at > @options[:timeout]
            child_process.stop
            raise ExecutionTimeout, "`#{@command}` took too much time to execute (timeout: #{@options[:timeout]}) #{child_process}"
          end
        end

        @wait_condition.complete(child_process)
        child_process
      end
    end

  end
end