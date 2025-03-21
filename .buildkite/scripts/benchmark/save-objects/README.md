benchmark_objects.ndjson contains the following resources

- Dashboards
  - daily snapshot
  - released versions
- Data Views
  - benchmark
    - runtime fields
      - | Fields Name  | Type         | Comment                                                                               |
        |--------------|---------------------------------------------------------------------------------------|--------------------------------------------------|
        | versions_num | long         | convert semantic versioning to number for graph sorting                               |
        | release      | boolean      | `true` for released version. `false` for snapshot version. It is for graph filtering. |
    
To import objects to Kibana, navigate to Stack Management > Save Objects and click Import