require "test_utils"

describe "..." do
  extend LogStash::RSpec

  config <<-'CONFIG'
    filter {
      grok {
        pattern => "%{COMBINEDAPACHELOG}"
      }
     
     
      date {
        # Try to pull the timestamp from the 'timestamp' field
        match => [ "timestamp", "dd'/'MMM'/'yyyy:HH:mm:ss Z" ]
      }
    }
  CONFIG

  line = '192.168.1.1 - - [25/Mar/2013:20:33:56 +0000] "GET /www.somewebsite.co.uk/dwr/interface/AjaxNewsletter.js HTTP/1.1" 200 794 "http://www.somewebsite.co.uk/money/index.html" "Mozilla/5.0 (Linux; U; Android 2.3.6; en-gb; GT-I8160 Build/GINGERBREAD) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1" "NREUM=s=1364243891214&r=589267&p=101913; __utma=259942479.284548354.1358973919.1363109625.1364243485.15; __utmb=259942479.4.10.1364243485; __utmc=259942479; __utmz=259942479.1359409342.3.3.utmcsr=investing.somewebsite.co.uk|utmccn=(referral)|utmcmd=referral|utmcct=/performance/overview/; asi_segs=D05509_10903|D05509_11337|D05509_11335|D05509_11341|D05509_11125|D05509_11301|D05509_11355|D05509_11508|D05509_11624|D05509_10784|D05509_11003|D05509_10699|D05509_11024|D05509_11096|D05509_11466|D05509_11514|D05509_11598|D05509_11599|D05509_11628|D05509_11681; rsi_segs=D05509_10903|D05509_11337|D05509_11335|D05509_11341|D05509_11125|D05509_11301|D05509_11355|D05509_11508|D05509_11624|D05509_10784|D05509_11003|D05509_10699|D05509_11024|D05509_11096|D05509_11466|D05509_11514|D05509_11598|D05509_11599|D05509_11628|D05509_11681|D05509_11701|D05509_11818|D05509_11850|D05509_11892|D05509_11893|D05509_12074|D05509_12091|D05509_12093|D05509_12095|D05509_12136|D05509_12137|D05509_12156|D05509_0; s_pers=%20s_nr%3D1361998955946%7C1364590955946%3B%20s_pn2%3D/money/home%7C1364245284228%3B%20s_c39%3D/money/home%7C1364245522830%3B%20s_visit%3D1%7C1364245693534%3B; s_sess=%20s_pn%3D/money/home%3B%20s_cc%3Dtrue%3B%20s_sq%3D%3B"'

  sample line do
    #puts subject["@timestamp"]
    #puts subject["timestamp"]
  end
end
