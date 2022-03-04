# Dependency audit tool

The dependency audit tool automates the verification of the following criteria for all
third-party dependencies that are shipped as part of either Logstash core or the [default Logstash 
plugins](https://github.com/elastic/logstash/blob/main/rakelib/plugins-metadata.json):
* The dependency has been added to the [dependency list file](https://github.com/elastic/logstash/blob/main/tools/dependencies-report/src/main/resources/licenseMapping.csv)
with an appropriate project URL and [SPDX license identifier](https://spdx.org/licenses/). 
* The license for the dependency is among those [approved for distribution](https://github.com/elastic/logstash/blob/main/tools/dependencies-report/src/main/resources/acceptableLicenses.csv).
* There is a corresponding `NOTICE.txt` file in the [notices folder](https://github.com/elastic/logstash/tree/main/tools/dependencies-report/src/main/resources/notices)
containing the appropriate notices or license information for the dependency. These individual 
notice files will be combined to form the notice file shipped with Logstash.

The dependency audit tool enumerates all the dependencies, Ruby and Java, direct and transitive,
for Logstash core and the default plugins. If any dependencies are found that do not conform to
the criteria above, the name of the dependency(ies) along with instructions for resolving are 
printed to the console and the tool exits with a non-zero return code.

The dependency audit tool should be run using the script in the `bin` folder:

`$LS_HOME/bin/dependencies-report --csv report.csv`
