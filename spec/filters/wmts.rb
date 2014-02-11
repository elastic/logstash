require "test_utils"
require "logstash/filters/wmts"

describe LogStash::Filters::Wmts do
  extend LogStash::RSpec

  describe "regular calls logged into Varnish logs (apache combined)" do
    config <<-CONFIG
      filter {
        # First, waiting for varnish log file formats (combined apache logs)
        grok { match => [ "message", "%{COMBINEDAPACHELOG}" ] }
        # Then, parameters 
        # Note: the 'wmts.' prefix should match the configuration of the plugin,
        # e.g if "wmts { 'prefix' => 'gis' }", then you should adapt the grok filter
        # accordingly.
        #
        grok {
          match => [
            "request", 
            "(?<wmts.version>([0-9\.]{5}))\/(?<wmts.layer>([a-z0-9\.-]*))\/default\/(?<wmts.release>([0-9]{8}))\/(?<wmts.reference-system>([0-9]*))\/(?<wmts.zoomlevel>([0-9]*))\/(?<wmts.row>([0-9]*))\/(?<wmts.col>([0-9]*))\.(?<wmts.filetype>([a-zA-Z]*))"]
        }
        wmts { }
      }
    CONFIG

    # regular WMTS query from a varnish log
    sample '127.0.0.1 - - [20/Jan/2014:16:48:28 +0100] "GET http://wmts4.testserver.org/1.0.0/' \
      'mycustomlayer/default/20130213/21781/23/470/561.jpeg HTTP/1.1" 200 2114 ' \
      '"http://localhost/ajaxplorer/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36' \
      '(KHTML, like Gecko) Ubuntu Chromium/31.0.1650.63 Chrome/31.0.1650.63 Safari/537.36"' do
        # checks that the query has been successfully parsed  
        # and the geopoint correctly reprojected into wgs:84 
        insist { subject["wmts.version"] } == "1.0.0"
        insist { subject["wmts.layer"] } == "mycustomlayer"
        insist { subject["wmts.release"] } == "20130213"
        insist { subject["wmts.reference-system"] } == "21781"
        insist { subject["wmts.zoomlevel"] } == "23"
        insist { subject["wmts.row"] } == "470"
        insist { subject["wmts.col"] } == "561"
        insist { subject["wmts.filetype"] } == "jpeg"
        insist { subject["wmts.service"] } == "wmts"
        insist { subject["wmts.input_epsg"] } == "epsg:21781"
        insist { subject["wmts.input_x"] } == 707488
        insist { subject["wmts.input_y"] } == 109104
        insist { subject["wmts.input_xy"] } == "707488,109104"
        insist { subject["wmts.output_epsg"] } == "epsg:4326"
        insist { subject["wmts.output_xy"] } == "8.829295858079231,46.12486163053951"
        insist { subject["wmts.output_x"] } == 8.829295858079231
        insist { subject["wmts.output_y"] } == 46.12486163053951
      end

    # query extracted from a varnish log, but not matching a wmts request
    sample '83.77.200.25 - - [23/Jan/2014:06:51:55 +0100] "GET http://map.schweizmobil.ch/api/api.css HTTP/1.1"' \
      ' 200 682 "http://www.schaffhauserland.ch/de/besenbeiz" ' \
      '"Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko"' do
        insist { subject["tags"] }.include?("_grokparsefailure")
    end

    # query looking like a legit wmts log but actually contains garbage [1]
    # - parameters from the grok filter cannot be cast into integers
    sample '127.0.0.1 - - [20/Jan/2014:16:48:28 +0100] "GET http://wmts4.testserver.org/1.0.0/' \
      'mycustomlayer/default/12345678////.raw HTTP/1.1" 200 2114 ' \
      '"http://localhost//" "ozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36' \
      '(KHTML, like Gecko) Ubuntu Chromium/31.0.1650.63 Chrome/31.0.1650.63 Safari/537.36"' do
         insist { subject['wmts.errmsg'] } == "Bad parameter received from the Grok filter"
    end

    # query looking like a legit wmts log but actually contains garbage
    # * 99999999 is not a valid EPSG code (but still parseable as an integer)
    sample '127.0.0.1 - - [20/Jan/2014:16:48:28 +0100] "GET http://wmts4.testserver.org/1.0.0/' \
      'mycustomlayer/default/20130213/99999999/23/470/561.jpeg HTTP/1.1" 200 2114 ' \
      '"http://localhost//" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36' \
      '(KHTML, like Gecko) Ubuntu Chromium/31.0.1650.63 Chrome/31.0.1650.63 Safari/537.36"' do
         insist { subject['wmts.errmsg'] } == "Unable to reproject tile coordinates"
    end
  end

  describe "Testing the epsg_mapping parameter" do
    config <<-CONFIG
      filter {
        grok { match => [ "message", "%{COMBINEDAPACHELOG}" ] }
        grok {
          match => [
            "request", 
            "(?<wmts.version>([0-9\.]{5}))\/(?<wmts.layer>([a-z0-9\.-]*))\/default\/(?<wmts.release>([0-9]*))\/(?<wmts.reference-system>([a-z0-9]*))\/(?<wmts.zoomlevel>([0-9]*))\/(?<wmts.row>([0-9]*))\/(?<wmts.col>([0-9]*))\.(?<wmts.filetype>([a-zA-Z]*))"]
        }
        wmts { epsg_mapping => { 'swissgrid' => 21781 } }
      }
    CONFIG

    # regular query needing a mapping
    sample '11.12.13.14 - - [10/Feb/2014:16:27:26 +0100] "GET http://tile1.wmts.example.org/1.0.0/grundkarte/default/2013/swissgrid/9/371/714.png HTTP/1.1" 200 8334 "http://example.org" "Mozilla/5.0 (Windows NT 6.1; rv:26.0) Gecko/20100101 Firefox/26.0"' do
      insist { subject["wmts.version"] } == "1.0.0"
      insist { subject["wmts.layer"] } == "grundkarte"
      insist { subject["wmts.release"] } == "2013"
      insist { subject["wmts.reference-system"] } == "swissgrid"
      insist { subject["wmts.zoomlevel"] } == "9"
      insist { subject["wmts.row"] } == "371"
      insist { subject["wmts.col"] } == "714"
      insist { subject["wmts.filetype"] } == "png"
      insist { subject["wmts.service"] } == "wmts"
      # it should have been correctly mapped
      insist { subject["wmts.input_epsg"] } == "epsg:21781"
      insist { subject["wmts.input_x"] } == 320516000
      insist { subject["wmts.input_y"] } == -166082000
      insist { subject["wmts.input_xy"] } == "320516000,-166082000"
      insist { subject["wmts.output_epsg"] } == "epsg:4326"
      insist { subject["wmts.output_xy"] } == "7.438691675813199,-43.38015041464443"
      insist { subject["wmts.output_x"] } == 7.438691675813199
      insist { subject["wmts.output_y"] } == -43.38015041464443
    end
 
    # regular query which does not need a mapping
    sample '11.12.13.14 - - [10/Feb/2014:16:27:26 +0100] "GET http://tile1.wmts.example.org/1.0.0/grundkarte/default/2013/21781/9/371/714.png HTTP/1.1" 200 8334 "http://example.org" "Mozilla/5.0 (Windows NT 6.1; rv:26.0) Gecko/20100101 Firefox/26.0"' do
      insist { subject["wmts.version"] } == "1.0.0"
      insist { subject["wmts.layer"] } == "grundkarte"
      insist { subject["wmts.release"] } == "2013"
      insist { subject["wmts.reference-system"] } == "21781"
      insist { subject["wmts.zoomlevel"] } == "9"
      insist { subject["wmts.row"] } == "371"
      insist { subject["wmts.col"] } == "714"
      insist { subject["wmts.filetype"] } == "png"
      insist { subject["wmts.service"] } == "wmts"
      insist { subject["wmts.input_epsg"] } == "epsg:21781"
      insist { subject["wmts.input_x"] } == 320516000
      insist { subject["wmts.input_y"] } == -166082000
      insist { subject["wmts.input_xy"] } == "320516000,-166082000"
      insist { subject["wmts.output_epsg"] } == "epsg:4326"
      insist { subject["wmts.output_xy"] } == "7.438691675813199,-43.38015041464443"
      insist { subject["wmts.output_x"] } == 7.438691675813199
      insist { subject["wmts.output_y"] } == -43.38015041464443
    end
  end
  describe "Testing a custom grid sent as parameter to the filter" do
    config <<-CONFIG
      filter {
        grok { match => [ "message", "%{COMBINEDAPACHELOG}" ] }
        grok {
          match => [
            "request", 
            "(?<wmts.version>([0-9\.]{5}))\/(?<wmts.layer>([a-z0-9\.-]*))\/default\/(?<wmts.release>([0-9]*))\/(?<wmts.reference-system>([a-z0-9]*))\/(?<wmts.zoomlevel>([0-9]*))\/(?<wmts.row>([0-9]*))\/(?<wmts.col>([0-9]*))\.(?<wmts.filetype>([a-zA-Z]*))"]
        }
        wmts { 
          epsg_mapping => { 'swissgrid' => 21781 }
          x_origin => 420000
          y_origin => 350000
          tile_width => 256
          tile_height => 256
          resolutions => [ 500, 250, 100, 50, 20, 10, 5, 2.5, 2, 1.5, 1, 0.5, 0.25, 0.1, 0.05 ]
        }
      }
    CONFIG

    sample '1.2.3.4 - - [10/Feb/2014:18:06:12 +0100] "GET http://tile1.example.net/1.0.0/ortho/default/2013/swissgrid/9/374/731.jpeg HTTP/1.1" 200 13872 "http://example.net" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.52 Safari/537.36"' do
      insist { subject["wmts.version"] } == "1.0.0"
      insist { subject["wmts.layer"] } == "ortho"
      insist { subject["wmts.release"] } == "2013"
      insist { subject["wmts.reference-system"] } == "swissgrid"
      insist { subject["wmts.zoomlevel"] } == "9"
      insist { subject["wmts.row"] } == "374"
      insist { subject["wmts.col"] } == "731"
      insist { subject["wmts.filetype"] } == "jpeg"
      insist { subject["wmts.service"] } == "wmts"
      insist { subject["wmts.input_epsg"] } == "epsg:21781"
      insist { subject["wmts.input_x"] } == 700896
      insist { subject["wmts.input_y"] } == 206192
      insist { subject["wmts.input_xy"] } == "700896,206192"
      insist { subject["wmts.output_epsg"] } == "epsg:4326"
      insist { subject["wmts.output_xy"] } == "8.765263559441715,46.999112812287045"
      insist { subject["wmts.output_x"] } == 8.765263559441715
      insist { subject["wmts.output_y"] } == 46.999112812287045
    end
  end
end

