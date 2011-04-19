
get '/search' do
  # TODO(sissel): Refactor this to use the api_search
  result_callback = proc do |results|
    status 500 if @error
    @results = results

    p :got => results

    params[:format] ||= "html"
    case params[:format]
    when "html"
      headers({"Content-Type" => "text/html" })
      body haml :"search/results", :layout => !request.xhr?
    when "text"
      headers({"Content-Type" => "text/plain" })
      body erb :"search/results.txt", :layout => false
    when "txt"
      headers({"Content-Type" => "text/plain" })
      body erb :"search/results.txt", :layout => false
    when "json"
      headers({"Content-Type" => "text/plain" })
      # TODO(sissel): issue/30 - needs refactoring here.
      hits = @hits.collect { |h| h["_source"] }
      response = {
        "hits" => hits,
      }

      response["error"] = @error if @error
      body response.to_json
    end # case params[:format]
  end # proc result_callback

  # We'll still do a search query here even though most users
  # have javascript enabled, we need to show the results in
  # case a user doesn't have javascript.
  if params[:q] and params[:q] != ""
    query = LogStash::Search::Query.new(
      :query_string => params[:q],
      :offset => params[:offset],
      :count => params[:count]
    )

    @backend.search(query) do |results|
      p :got => results
      begin
        result_callback.call results
      rescue => e
        p :exception => e
      end
    end # @backend.search
  else
    results = LogStash::Search::Result.new(
      :events => [],
      :error_message => "No query given"
    )
    result_callback.call results
  end
end # get '/search'

