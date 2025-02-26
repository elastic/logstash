---
navigation_title: "Troubleshooting"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/monitoring-troubleshooting.html
---

# Troubleshooting monitoring in Logstash [monitoring-troubleshooting]



## Logstash Monitoring Not Working After Upgrade [_logstash_monitoring_not_working_after_upgrade]

When upgrading from older versions, the built-in `logstash_system` user is disabled for security reasons. To resume monitoring:

1. Change the `logstash_system` password:

    ```console
    PUT _security/user/logstash_system/_password
    {
      "password": "newpassword"
    }
    ```

2. Re-enable the `logstash_system` user:

    ```console
    PUT _security/user/logstash_system/_enable
    ```


