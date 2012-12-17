VERSION=`git describe --tags|cut -f1-2 -d '-'`
echo Building logstash $VERSION ...
# make jar
ROOT=`dirname $0`
ROOT=`cd $ROOT; pwd`
REPO_DIR=$ROOT/repo/$VERSION
mkdir -p $REPO_DIR
REPO=file://$REPO_DIR
rm -rf $REPO_DIR

mvn deploy:deploy-file -Durl=$REPO \
                       -DrepositoryId=localRepo \
                       -Dfile=build/logstash-1.1.6.dev-monolithic.jar \
                       -DgroupId=net.logstash \
                       -DartifactId=logstash \
                       -Dversion=$VERSION \
                       -Dpackaging=jar \
                       -DgeneratePom=true \
                       -DgeneratePom.description="Logstash Jar" \
                       -DrepositoryLayout=default \
                       -DuniqueVersion=false

# Zipping up the repo
if [ -d $REPO_DIR ]
then
  cd $REPO_DIR
  zip -r logstash-$VERSION.zip *
fi

