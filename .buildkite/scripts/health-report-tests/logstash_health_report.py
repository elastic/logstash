"""
A class to provide information about Logstash node stats.
"""

import util


class LogstashHealthReport:
    LOGSTASH_HEALTH_REPORT_URL = "http://localhost:9600/_health_report"

    def __init__(self):
        pass

    def get(self):
        response = util.call_url_with_retry(self.LOGSTASH_HEALTH_REPORT_URL)
        return response.json()
