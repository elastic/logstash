require 'net/http'
require 'uri'
require 'json'
require 'timeout'
require 'shellwords'
require 'pathname'

module SharedHelpers
  def es_request(path, body = nil)
    es_url = @es_url || "https://localhost:9200"
    es_user = @es_user || 'elastic'
    es_password = @es_password || 'changeme'
    
    uri = URI.parse(es_url + path)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = body ? Net::HTTP::Post.new(uri.request_uri) : Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth(es_user, es_password)
    request["Content-Type"] = "application/json"
    request.body = body if body

    http.request(request)
  end

  def wait_until(timeout: 30, interval: 1, message: nil)
    Timeout.timeout(timeout) do
      loop do
        break if yield
        sleep interval
      end
    end
  rescue Timeout::Error
    raise message || "Condition not met within #{timeout} seconds"
  end

  def wait_for_elasticsearch(max_retries = 120, require_documents: false, index_pattern: nil)
    retries = 0
    ready = false

    while !ready && retries < max_retries
      begin
        response = es_request("/_cluster/health")
        if response.code == "200"
          health = JSON.parse(response.body)
          if ["green", "yellow"].include?(health["status"])
            if require_documents && index_pattern
              logs_response = es_request("/#{index_pattern}/_count")
              if logs_response.code == "200"
                count_data = JSON.parse(logs_response.body)
                if count_data["count"] > 0
                  ready = true
                  puts "Found #{count_data["count"]} documents in #{index_pattern} index"
                else
                  puts "Waiting for documents in #{index_pattern} index..."
                  puts "ES response: #{count_data.inspect}"
                end
              end
            else
              ready = true
            end
          end
        end
      rescue => e
        puts "Waiting for Elasticsearch: #{e.message}"
      ensure
        unless ready
          retries += 1
          sleep 1
          puts "Retry #{retries}/#{max_retries}"
        end
      end
    end

    raise "System not ready after #{max_retries} seconds" unless ready
  end

  def docker_compose_invoke(subcommand, env = {}, work_dir)
    env_str = env.map{ |k,v| "#{k.to_s.upcase}=#{Shellwords.escape(v)} "}.join
    command = "#{env_str}docker-compose --project-directory=#{Shellwords.escape(work_dir)} #{subcommand}"
    puts "Invoking Docker Compose with command: #{command}"
    system(command) or fail "Failed to invoke Docker Compose with command `#{command}`"
  end

  def docker_compose_up(env = {}, work_dir)
    docker_compose_invoke("up --detach", env, work_dir)
  end

  def docker_compose_down(env = {}, work_dir)
    docker_compose_invoke("down --volumes", env, work_dir)
  end
end