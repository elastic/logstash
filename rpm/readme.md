# RPM build

spectool -g SPECS/logstash.spec
rpmbuild -bb SPECS/logstash.spec
