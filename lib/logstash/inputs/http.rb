require "openssl"
require "webrick"
require "webrick/ssl"
require "logstash/namespace"
require "logstash/inputs/base"
require "thread"

# Reads log events from a http endpoint.
#
# Configuring this plugin can be done using the following basic configuration:
#
# input {
#   http { }
# }
#
# This will open a http server on port 8000 that accepts messages in the JSON
# format. You can customize the port and bind address in the options of the
# plugin.

class LogStash::Inputs::Http < LogStash::Inputs::Base
	config_name "http"
	milestone 1

	default :codec, "json"

	# The port to listen on. Default is 8000.
	config :port, :validate => :number, :default => 8000

	# The address to bind on. Default is 0.0.0.0
	config :address, :validate => :string, :default => "0.0.0.0"

	def register
		options =  { :Port => @port, :BindAddress => @address }

		# Start a basic HTTP server to receive logging information.
		@http_server = WEBrick::HTTPServer.new options
	end

	def run(output_queue)
		begin
			@mutex = Mutex.new
			@wait_handle = ConditionVariable.new

			# Register a custom procedure with the HTTP server so that we can receive log messages
			# and process them using this plugin.
			@http_server.mount_proc '/' do |req, res|
				codec = @codec.clone

				# Decode the incoming body and store it in the event queue.
				codec.decode(req.body) do |event|
					# Add additional logging data to the event
					event["host"] = req.peeraddr

					# Decorate the event with the mandatory logstash stuff.
					decorate(event)

					# Push the event in the output queue
					output_queue << event
				end

				# Send a HTTP 100 continue response without content.
				# This acknowledges the logger that the content was received.
				res.status = 200
				res.body = "{ \"status\": \"OK\" }"
			end

			# Start the webserver.
			# Start a separate thread for the http server
			@server_thread = Thread.new do
				@http_server.start
			end

			@logger.info "HTTP listener registered on #{@address}:#{@port}."

			# This somewhwat weird construction is required, because Logstash expects the run
			# method to run forever. Which is the case right here ;-)
			@mutex.synchronize do
				@wait_handle.wait(@mutex)
			end
		ensure
			# Close the HTTP server at the end of the run method.
			# This ensures that the sockets used are closed.
			@http_server.shutdown
		end
	end

	def teardown
		# Interrupt the listener and stop the process.
		@mutex.synchronize do
			@wait_handle.signal
		end
	end
end
