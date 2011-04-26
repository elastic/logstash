if [ -z "$1" ] ; then
  echo "Usage: $0 dir1 ..."
  exit 1
fi

set -e

echo "---"
echo "title: logstash docs index"
echo "layout: default"
echo "---"

for i in "$@"; do
  (
    cd $i
    find inputs filters outputs -type f -name '*.markdown' \
      | sed -e 's,\.markdown$,,; s,.*,[&](&),' \
  )
done


