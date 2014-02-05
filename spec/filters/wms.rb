require "test_utils"
require "logstash/filters/wms"

describe LogStash::Filters::Wms do
  extend LogStash::RSpec

  describe "regular calls logged into Varnish logs (apache combined)" do
    config <<-CONFIG
      filter {
        grok { match => [ "message", "%{COMBINEDAPACHELOG}" ] }
       wms { }
      }
    CONFIG

    # regular WMS query (GetCapabilities) from varnish logs
    sample '12.13.14.15 - - [23/Jan/2014:06:52:00 +0100] "GET http://wms.myserver.com/?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities' \
    ' HTTP/1.1" 200 202 "http://referer.com" "ArcGIS Client Using WinInet"' do
      insist { subject["wms.service"] } == "wms"
      insist { subject["wms.version"] } == "1.3.0"
      insist { subject["wms.request"] } == "getcapabilities"
    end

    # WMS query (GetMap) from varnish logs
    sample '12.34.56.78 - - [23/Jan/2014:06:52:20 +0100] "GET http://tile2.wms.de/mapproxy/service/?FORMAT=image%2Fpng&LAYERS=WanderlandEtappenNational,WanderlandEtappenRegional,WanderlandEtappenLokal,WanderlandEtappenHandicap&TRANSPARENT=TRUE&SERVICE=WMS&VERSION=1.1.1&REQUEST=GetMap&STYLES=&SRS=EPSG%3A21781&BBOX=804000,30000,932000,158000&WIDTH=256&HEIGHT=256 HTTP/1.1" 200 1447 "http://map.wanderland.ch/?lang=de&route=all&layer=wanderwegnetz" "Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.2; WOW64; Trident/6.0)"' do
       insist { subject["wms.service"] } == "wms"
       insist { subject["wms.version"] } == "1.1.1"
       insist { subject["wms.request"] } == "getmap"
       insist { subject["wms.layers"] } == ["wanderlandetappennational", "wanderlandetappenregional", "wanderlandetappenlokal", "wanderlandetappenhandicap"]
       insist { subject["wms.styles"] } == ""
       insist { subject["wms.srs"] } == "epsg:21781"
       insist { subject["wms.input_bbox.minx"] } == 804000.0
       insist { subject["wms.input_bbox.miny"] } == 30000.0
       insist { subject["wms.input_bbox.maxx"] } == 932000.0
       insist { subject["wms.input_bbox.maxy"] } == 158000.0
       insist { subject["wms.output_bbox.minx"] } == 10.043259272201887
       insist { subject["wms.output_bbox.miny"] } == 45.39141145053888
       insist { subject["wms.output_bbox.maxx"] } == 11.764979420793644
       insist { subject["wms.output_bbox.maxy"] } == 46.49090648227697
       insist { subject["wms.width"] } == "256"
       insist { subject["wms.height"] } == "256"
       insist { subject["wms.format"] } == "image/png"
       insist { subject["wms.transparent"] } == "true"
     end
  end
  # we will no use only the request part without grok for readability
  describe "regular calls (message containing only the request URI)" do
    config <<-CONFIG
      filter {
       wms { }
      }
    CONFIG
    # illegal SRS provided
    sample 'http://tile2.wms.de/mapproxy/service/?SERVICE=WmS&SRS=EPSG%3A9999999&BBOX=804000,30000,932000,158000' do
      insist { subject["wms.errmsg"] } == "Unable to reproject the bounding box"
    end
    # no reprojection needed
    sample 'http://tile2.wms.de/mapproxy/service/?SERVICE=WmS&SRS=EPSG%3A4326&BBOX=804000,30000,932000,158000' do
      insist { subject["wms.input_bbox.minx"] } == subject["wms.output_bbox.minx"]
      insist { subject["wms.input_bbox.miny"] } == subject["wms.output_bbox.miny"]
      insist { subject["wms.input_bbox.maxx"] } == subject["wms.output_bbox.maxx"]
      insist { subject["wms.input_bbox.maxy"] } == subject["wms.output_bbox.maxy"]
    end
    # bbox provided without SRS (probably not valid in WMS standard)
    # no reproj needed either
    sample 'http://tile2.wms.de/mapproxy/service/?SERVICE=WmS&BBOX=804000,30000,932000,158000' do
      insist { subject["wms.input_bbox.minx"] } == subject["wms.output_bbox.minx"]
      insist { subject["wms.input_bbox.miny"] } == subject["wms.output_bbox.miny"]
      insist { subject["wms.input_bbox.maxx"] } == subject["wms.output_bbox.maxx"]
      insist { subject["wms.input_bbox.maxy"] } == subject["wms.output_bbox.maxy"]
    end
    # illegal bbox provided
    sample 'http://tile2.wms.de/mapproxy/service/?SERVICE=WmS&CRS=EPSG%3A2154&BBOX=8040NOTAVALIDBBOX93084' do
      insist { subject["wms.errmsg"] } == "Unable to parse the bounding box"
    end


  end

end

