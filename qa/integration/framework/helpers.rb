# encoding: utf-8
# Helper module for all tests

require "flores/random"

def wait_for_port(port, retry_attempts)
  tries = retry_attempts
  while tries > 0
    if is_port_open?(port)
      break
    else
      sleep 1
    end
    tries -= 1
  end
end

def is_port_open?(port)
  begin
    s = TCPSocket.open("localhost", port)
    s.close
    return true
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
    return false
  end
end

def send_data(port, data)
  socket = TCPSocket.new("127.0.0.1", port)
  socket.puts(data)
  socket.flush
  socket.close
end

def config_to_temp_file(config)
  f = Stud::Temporary.file
  f.write(config)
  f.close
  f.path
end

def random_port
  # 9600-9700 is reserved in Logstash HTTP server, so we don't want that
  Flores::Random.integer(9701..15000)
end  