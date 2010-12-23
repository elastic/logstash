(function() {

  var logstash = {
    params: { 
      offset: 0,
      count: 50,
    },

    search: function(query) {
      logstash.params.q = query;
      document.location.hash = escape(JSON.stringify(logstash.params));
      $("#results").load("/search/ajax", logstash.params);
      $("#query").val(logstash.params.q);
    }, /* search */

    parse_params: function(href) {
      var params = href.replace(/^[^?]*\?/, "").split("&")
      for (var p in params) {
        var a = params[p].split("=");
        var key = a[0]
        var value = a[1]
        logstash.params[key] = unescape(value)
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

    $("a.pager").live("click", function() {
      var href = $(this).attr("href");
      var params = logstash.parse_params(location.href);
      for (var p in params) {
        logstash.params[p] = params[p];
      }
      logstash.search(logstash.params.q)
      return false;
    });

    $("a.querychanger").live("click", function() {
      var href = $(this).attr("href");
      var re = new RegExp("[&?]q=([^&]+)");
      var match = re.exec(href);
      if (match) {
        logstash.search(match[1]);
      }
      return false;
    });

    var result_row_selector = "table.results tr.event";
    $(result_row_selector).live("click", function() {
      var data = eval($("td.message", this).data("full"));

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
      for (var i in data._source["@fields"]) {
        var value = data._source["@fields"][i]
        if (/^[, ]*$/.test(value)) {
          continue; /* Skip empty data fields */
        }
        if (!(value instanceof Array)) {
          value = [value];
        }
        fields.push( { type: "field", field: i, value: value })
      }

      for (var i in data._source) {
        if (i == "@fields") continue;
        var value = data._source[i]
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
