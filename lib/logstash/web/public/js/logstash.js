(function() {
  // TODO(sissel): this code could use serious refactorlove.
  // TODO(sissel): Write something that will use history.pushState and fall back
  // to document.location.hash madness.
  
  if (typeof(window.console) === 'undefined') {
    window.console = { 
      log: function() { 
        // no-op if we don't have a console logger.
      }
    };
  }

  var logstash = {
    params: { 
      offset: 0,
      count: 50,
    },

    search: function(query, options) {
      if (query == undefined || query == "") {
        return;
      }

      /* Default options */
      if (typeof(options) == 'undefined') {
        options = { graph: true };
      }

      /* Check for history.pushState */

      var display_query = query.replace("<", "&lt;").replace(">", "&gt;")
      $("#querystatus, #results h1").html("Loading query '" + display_query + "' (offset:" + logstash.params.offset + ", count:" + logstash.params.count + ") <img class='throbber' src='/media/throbber.gif'>")
      //console.log(logstash.params)
      logstash.params.q = query;

      /* Load the search results */
      $("#results").load("/api/search?format=html", logstash.params);

      if (options.graph != false) {
        /* Load the default histogram graph */
        logstash.params.interval = 3600000; /* 1 hour, default */
        logstash.histogram();
      } /* if options.graph != false */
      $("#query").val(logstash.params.q);
      logstash.hash = document.location.hash = escape(JSON.stringify(logstash.params));
    }, /* search */

    histogram: function(tries) {
      if (typeof(tries) == 'undefined') {
        /* GeoCities mode on the graph while waiting ...
         * This won't likely survive 1.0, but it's fun for now... 
         * TODO(sissel): Replace with a 'loading' or something icon. */

        $("#visual").html("<center><img src='/media/throbber.gif'><center>");

        tries = 4; /* default tries */
      }

      jQuery.getJSON("/api/histogram", logstash.params, function(histogram, text, jqxhr) {
        /* Load the data into the graph */
        var flot_data = [];
        // histogram is an array of { "key": ..., "count": ... }
        for (var i in histogram) {
          flot_data.push([parseInt(histogram[i]["key"]), histogram[i]["count"]])
        }

        /* Try to be intelligent about how we choose the histogram interval.
         * If there are too few data points, try a smaller interval.
         * If there are too many data points, try a larger interval.
         * Give up after a few tries and go with the last result. 
         *
         * This queries the backend several times, but should be reasonably
         * speedy as this behaves roughly as a binary search. */

        /* I originally used '2' for this value for binary search-like tuning
         * on the graph interval, but it's not fast enough, so use 3 for now.
         */
        jumpsize = 3
        if (tries > 0 && logstash.params.interval > 1000) {
          if (flot_data.length < 6 && flot_data.length > 0) {
            console.log("Histogram bucket " + logstash.params.interval + " has only " + flot_data.length + " data points, trying smaller...");
            logstash.params.interval /= jumpsize;
          } else if (flot_data.length > 50) {
            console.log("Histogram bucket " + logstash.params.interval + " too many (" + flot_data.length + ") data points, trying larger interval...");
            logstash.params.interval *= jumpsize;
          }
          logstash.histogram(tries - 1);
          return;
        } else {
          /* Got a good interval, plot it */
          logstash.plot(flot_data, logstash.params.interval);
        }
      });
    },

    parse_params: function(href) {
      var query = href.replace(/^[^?]*\?/, "");
      if (query == href) {
        //console.log("No query params in link " + href);
        /* No query params */
        return {};
      }

      //console.log({ "query": query });
      var param_list = query.split("&");
      params = {};
      //console.log({ "Parsed params": params });
      for (var p in param_list) {
        var a = param_list[p].split("=");
        var key = a[0];
        var value = a[1];
        params[key] = unescape(value);
      }
      return params;
    },

    appendquery: function(query) {
      var newquery = $("#query").val();
      newquery += " " + query;
      logstash.search(newquery.trim());
    }, /* appendquery */

    plot: function(data, interval) {
      var target = $("#visual");
      target.css("display", "block");
      target.children().remove();
      console.log("Plotting data")
      console.log(data)

      var plot = $.plot(target,
        [ {  /* data */
            data: data,
            bars: { 
              show: true,
              barWidth: interval,
            }
        } ],
        { /* options */
          xaxis: { mode: "time" },
          grid: { hoverable: true, clickable: true },
        }
      );

      /* Remove any previous bindings on this plot
       * If we don't do this, then all previously-registered events will fire
       * for this plot when clicked, and that's bad. */
      target.unbind("plotclick");
      target.bind("plotclick", function(e, pos, item) {
        if (item) {
          /* The following commented code should not be necessary anymore since I
           * believe I fixed the 'multiple plotclick' bug. */
          //var now = (new Date()).getTime();
          //if (now - logstash.last_plot_click < 50) { 
            /* TODO(sissel): debug why this happens.
             * For some reason, sometimes clicking on the plot will result in
             * more than one click event being fired. I've seen up to 5 'clicks'
             * being fired for the same event. Very strange.
             *
             * This hack should block extra/buggy clicks from being processed.
             */ 
            //console.log("Skipping extra click on plot?")
            //return;
          //}
          //console.log("plotclick; last time: " + (now - logstash.last_plot_click));
          //logstash.last_plot_click = now;
          console.log(e, pos, item)
          start = logstash.ms_to_iso8601(item.datapoint[0]);
          end = logstash.ms_to_iso8601(item.datapoint[0] + interval);

          /* Clicking on the graph means a new search, means
           * we probably don't want to keep the old offset since
           * the search results will change. */
          logstash.params.offset = 0;
          logstash.appendquery("@timestamp:[" + start + " TO " + end + "]");
        }
      });
    }, /* plot */

    ms_to_iso8601: function(milliseconds) {
      /* From: 
       * https://developer.mozilla.org/en/JavaScript/Reference/global_objects/date#Example.3a_ISO_8601_formatted_dates
       */
      var d = new Date(milliseconds);
      function pad(n){return n<10 ? '0'+n : n}
      return d.getUTCFullYear()+'-'
        + pad(d.getUTCMonth()+1)+'-'
        + pad(d.getUTCDate())+'T'
        + pad(d.getUTCHours())+':'
        + pad(d.getUTCMinutes())+':'
        + pad(d.getUTCSeconds())+'Z'
    },
  }; /* logstash */

  window.logstash = logstash;

  $().ready(function() {
    if (location.hash.length > 1) {
      try {
        logstash.params = JSON.parse(unescape(location.hash.substring(1)));
      } catch (e) {
        // Do nothing 
      }
      logstash.search(logstash.params.q);
    } else {
      /* No hash. See if there's a query param. */
      var params = logstash.parse_params(location.href);
      //console.log(params)
      for (var p in params) {
        logstash.params[p] = params[p];
      }
      logstash.search(logstash.params.q)
    }

    $(window).hashchange(function() {
      /* Sometimes hashchange is called when we change the hash ourselves from
       * javascript. We don't want that. */
      if (logstash.hash === location.hash.substring(1)) {
        console.log("Ignoring superfluous hashchange")
        return;
      }
      logstash.params = JSON.parse(unescape(location.hash.substring(1)));
      console.log("hashchange");
      query = logstash.params.q
      if (query != $("#query").val()) {
        scroll(0, 0); 
        logstash.search(query);
      }
    });

    $("a.pager, a.querychanger").live("click", function() {
      /* TODO(sissel): Allow 'control click' and 'middle click' to act normally */
      var href = $(this).attr("href");
      var params = logstash.parse_params(href);
      for (var p in params) {
        logstash.params[p] = params[p];
      }
      logstash.search(logstash.params.q, { graph: false })
      return false;
    });

    var result_row_selector = "table.results tr.event";
    $(result_row_selector).live("click", function() {
      var data = $("td.message", this).data("full");
      if (typeof(data) == "string") {
        data = JSON.parse(data);
      }

      /* Apply template to the dialog */
      var query = $("#query").val().replace(/^\s+|\s+$/g, "")
      var sanitize = function(str) {
        if (!/^".*"$/.test(str)) {
          str = '"' + str + '"';
        }
        return escape(str);
      };

      var template = $.template("inspector",
        "<li>" +
          "<b>(${type}) ${field}</b>:" +
          "{{each(idx, val) value}}" +
            "<a href='/search?q=" + query + " ${escape(field)}:${$item.sanitize(val)}'" +
            "   data-field='${escape(field)}' data-value='${$item.sanitize(val)}'>" +
              "${val}" +
            "</a>, " +
          "{{/each}}" +
        "</li>");

      /* TODO(sissel): recurse through the data */
      var fields = new Array();
      for (var i in data["@fields"]) {
        var value = data["@fields"][i]
        if (/^[, ]*$/.test(value)) {
          continue; /* Skip empty data fields */
        }
        if (!(value instanceof Array)) {
          value = [value];
        }
        fields.push( { type: "field", field: i, value: value })
      }

      for (var i in data) {
        if (i == "@fields") continue;
        var value = data[i]
        if (!(value instanceof Array)) {
          value = [value];
        }

        if (i.charAt(0) == "@") { /* metadata */
          fields.push( { type: "metadata", field: i, value: value });
        } else { /* data */
          if (/^[, ]*$/.test(value)) {
            continue; /* Skip empty data fields */
          }
          fields.push( { type: "field", field: i, value: value })
        }
      }

      //for (var i in data) {
        //if (i == "_source") {
          //continue; /* already processed this one */
        //}
        //value = data[i]
        //if (!(value instanceof Array)) {
          //value = [value];
        //}
        //fields.push( { type: "metadata", field: i, value: value })
      //}

      fields.sort(function(a, b) {
        if (a.type+a.field < b.type+b.field) { return -1; }
        if (a.type+a.field > b.type+b.field) { return 1; }
        return 0;
      });

      $(result_row_selector).removeClass("selected")
      $(this).addClass("selected");
      var entry = this;
      $("#inspector li").remove()
      $("#inspector")
        .append($.tmpl("inspector", fields, { "sanitize": sanitize }))
        .dialog({ 
          width: 400,
          title: "Fields for this log" ,
          closeOnEscape: true,
          position: ["right", "top"],
        });
    });

    $("#inspector li a").live("click", function(ev) {
      var field = $(this).data("field");
      var value = $(this).data("value");
      var query = $("#query");
      var newcondition = unescape(field) + ":" + unescape(value);

      var newquery = query.val();
      if (ev.shiftKey) {
        // Shift-click will make a "and not" condition
        query.val(newquery + " -" + newcondition)
      } else {
        query.val(newquery + " " + newcondition)
      }
      logstash.search(query.val())
      return false;
    });

    $("#searchbutton").bind("click submit", function(ev) {
      var query = $("#query").val().replace(/^\s+|\s+$/g, "")
      /* Search now, we pressed the submit button */
      logstash.search(query)
      return false;
    });
  }); /* $().ready */
})(); /* function scoping */
