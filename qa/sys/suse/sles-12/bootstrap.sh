#!/usr/bin/env bash

zypper rr systemsmanagement_puppet
zypper addrepo -t yast2 http://demeter.uni-regensburg.de/SLES12-x64/DVD1/ dvd1 || true
zypper addrepo -t yast2 http://demeter.uni-regensburg.de/SLES12-x64/DVD2/ dvd2 || true
zypper addrepo http://download.opensuse.org/repositories/Java:Factory/SLE_12/Java:Factory.repo || true
zypper --no-gpg-checks --non-interactive refresh
zypper --non-interactive list-updates
ln -s /usr/sbin/update-alternatives /usr/sbin/alternatives
curl -L 'https://edelivery.oracle.com/otn-pub/java/jdk/8u77-b03/jdk-8u77-linux-x64.rpm' -H 'Accept-Encoding: gzip, deflate, sdch' -H 'Accept-Language: en-US,en;q=0.8' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0' -H 'Cookie: oraclelicense=accept-securebackup-cookie;' -H 'Connection: keep-alive' --compressed -o oracle_jdk_1.8.rpm
zypper -q -n --non-interactive install oracle_jdk_1.8.rpm
