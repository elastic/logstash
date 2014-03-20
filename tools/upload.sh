
basedir=$(dirname $0)/../
bucket=download.elasticsearch.org

s3cmd put -P $basedir/build/release/build/*.gz s3://${bucket}/logstash/logstash/
s3cmd put -P $basedir/build/release/build/*.rpm s3://${bucket}/logstash/logstash/packages/centos/
s3cmd put -P $basedir/build/release/build/*.deb s3://${bucket}/logstash/logstash/packages/debian
s3cmd put -P $basedir/build/release/build/*.deb s3://${bucket}/logstash/logstash/packages/ubuntu
