class LogStash::Web::Server < Sinatra::Base
  # Mizuno can't serve static files from a jar
  # https://github.com/matadon/mizuno/issues/9
  #if __FILE__ =~ /^file:.+!.+$/
    get '/js/*' do static_file end
    get '/css/*' do static_file end
    get '/media/*' do static_file end
    get '/ws/*' do static_file end
  #else
    ## If here, we aren't running from a jar; safe to serve files
    ## through the normal public handler.
    #set :public, "#{File.dirname(__FILE__)}/public"
  #end

  def static_file
    # request.path_info is the full path of the request.
    path = File.join(File.dirname(__FILE__), "..", "public", *request.path_info.split("/"))
    #p :static => path
    if File.exists?(path)
      ext = path.split(".").last
      case ext
        when "js"; content_type "application/javascript"
        when "css"; content_type "text/css"
        when "jpg"; content_type "image/jpeg"
        when "jpeg"; content_type "image/jpeg"
        when "png"; content_type "image/png"
        when "gif"; content_type "image/gif"
      end

      body File.new(path, "r").read
    else
      status 404
      content_type "text/plain"
      body "File not found: #{path}"
    end
  end # def static_file
end # class LogStash::Web::Server

