(function() {
  // TODO(sissel): Write something that will use history.pushState and fall back
  // to document.location.hash madness.

  var logstash = {
    params: { 
      offset: 0,
      count: 50,
    },

    search: function(query) {
      if (query == undefined || query == "") {
        return;
      }
      //console.log("Searching: " + query);

      var display_query = query.replace("<", "&lt;").replace(">", "&gt;")
      $("#querystatus").html("Loading query '" + display_query + "'")
      //console.log(logstash.params)
      logstash.params.q = query;
      document.location.hash = escape(JSON.stringify(logstash.params));

      /* Load the search results */
      $("#results").load("/api/search?format=html", logstash.params);

      /* Load the default histogram graph */
      jQuery.getJSON("/api/histogram", logstash.params, function(histogram, text, jqxhr) {
        /* Load the data into the graph */
        flot_data = [];
        // histogram is an array of { "key": ..., "count": ... }
        for (var i in histogram) {
          flot_data.push([parseInt(histogram[i]["key"]), histogram[i]["count"]])
        }

        logstash.plot(flot_data);
      });
      $("#query").val(logstash.params.q);
    }, /* search */

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

    plot: function(data) {
      var target = $("#visual");
      target.css("display", "block");
      var plot = $.plot(target,
        [ {  /* data */
            data: data,
            bars: { 
              show: true,
              barWidth: 3600000,
            }
        } ],
        { /* options */
          xaxis: { mode: "time" },
          grid: { hoverable: true, clickable: true },
        }
      );

      target.bind("plotclick", function(e, pos, item) {
        if (item) {
          start = logstash.ms_to_iso8601(item.datapoint[0]);
          end = logstash.ms_to_iso8601(item.datapoint[0] + 3600000);

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
      logstash.params = JSON.parse(unescape(location.hash.substring(1)));
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
      logstash.search(logstash.params.q)
      return false;
    });

    var result_row_selector = "table.results tr.event";
    $(result_row_selector).live("click", function() {
      var data_json =$("td.message", this).data("full");
      //console.log(data_json);
      var data = JSON.parse(data_json);

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

      for (var i in data) {
        if (i == "_source") {
          continue; /* already processed this one */
        }
        value = data[i]
        if (!(value instanceof Array)) {
          value = [value];
        }
        fields.push( { type: "metadata", field: i, value: value })
      }

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
