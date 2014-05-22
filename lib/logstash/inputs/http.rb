require "openssl"
require "webrick"
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

	# The mode to run in. Use 'client' to pull requests from a specific url.
	# Use 'server' to enable clients to push events to this plugin.
	config :mode, :validate => :string, :default => 'server'

	# The url to fetch the log events from when running in client mode.
	# Currently supports only GET based requests.
	config :url, :validate => :string, :required => false

	# The interval between pull requests for new log events in milliseconds.
	# By default polls every second for new data. Increase or decrease as needed.
	config :interval, :validate => :number, :default => 1000

	def register
		options =  { :Port => @port, :BindAddress => @address }

		# Start a basic HTTP server to receive logging information.
		@http_server = WEBrick::HTTPServer.new options
	end

	def run(output_queue)
		if @mode == 'server'
			runserver output_queue
		else
			runclient output_queue
		end
	end

	def runclient(output_queue)
		while not @interrupted do
			begin

				output_queue << pull_event

				# Check if an interrupt came through.
				# When it did, stop this process.
				if @interrupted
					break
				end

				# Wait for the interval to pass, rinse and repeat the whole process.
				sleep @interval
			rescue LogStash::ShutdownSignal
				@interrupted = true
				break
			rescue Exception => error
				@logger.debug("Failed to retrieve log data from source.")
			end
		end
	end

	def pull_event()
		codec = @codec.clone

		# Download potentially new log data from the specified URL
		# Not using accept-type in the request, because we don't know the
		# content-type until we process it using the codec.
		response_body = HTTP.get @url

		# Use the codec to decode the data into something useful.
		codec.decode(response_body) do |event|
			# Decorate the event with the mandatory logstash stuff.
			decorate(event)

			return event
		end
	end

	def runserver(output_queue)
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
		if @mode == 'server'
			# Interrupt the listener and stop the process.
			@mutex.synchronize do
				@wait_handle.signal
			end
		else
			# Interrupt the client
			@interrupted = true
		end
	end
end
