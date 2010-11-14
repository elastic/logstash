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

      //target.bind("plothover", function(e, pos, item) {
        //console.log(item);
      //})
      target.bind("plotclick", function(e, pos, item) {
        if (item) {
          //console.log(item);
          start = item.datapoint[0];
          end = start + 3600000;
          console.log(start, end);
        }
      });
    }, /* plot */
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
    }

    $(window).hashchange(function() {
      logstash.params = JSON.parse(unescape(location.hash.substring(1)));
      query = logstash.params.q
      if (query != $("#query").val()) {
        scroll(0, 0); 
        logstash.search(query);
      }
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

    $("ul.results li.event").live("click", function() {
      var data = eval($(this).data("full"));

      /* Apply template to the dialog */
      var query = $("#query").val().replace(/^\s+|\s+$/g, "")
      console.log(query)
      var sanitize = function(str) {
        if (!/^".*"$/.test(str)) {
          str = '"' + str + '"';
        }
        return escape(str);
      };

      console.log(sanitize("hello world"));
      var template = $.template("inspector",
        "<li>" +
          "<b>(${type}) ${field}</b>:" +
          "<a href='/search?q=" + query + " AND ${escape(field)}:${$item.sanitize(value)}'" +
          "   data-field='${escape(field)}' data-value='${$item.sanitize(value)}'>" +
            "${value}" +
          "</a>" +
        "</li>");

      /* TODO(sissel): recurse through the data */
      var fields = new Array();
      for (var i in data._source["@fields"]) {
        var value = data._source["@fields"][i]
        if (/^[, ]*$/.test(value)) {
          continue; /* Skip empty data fields */
        }
        fields.push( { type: "field", field: i, value: value })
      }

      for (var i in data._source) {
        if (i == "@fields") continue;
        var value = data._source[i]
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
        fields.push( { type: "metadata", field: i, value: data[i] })
      }

      fields.sort(function(a, b) {
        if (a.type+a.field < b.type+b.field) { return -1; }
        if (a.type+a.field > b.type+b.field) { return 1; }
        return 0;
      });

      $("ul.results li.selected").removeClass("selected")
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
      if (newquery.length != 0) {
        newquery += " AND ";
      }
      if (ev.shiftKey) {
        // Shift-click will make a "and not" condition
        query.val(newquery + "-" + newcondition)
      } else {
        query.val(newquery + newcondition)
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
