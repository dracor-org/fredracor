#!/bin/bash

THREADS=6
CONTAINERS=[] # TODO: put container ids here, to stop them afterwards

THIS_DIR="$PWD"
WORK_DIR="/tmp/fredracor"
SOURCE_DIR="$WORK_DIR/data"
TARGET_DIR="$WORK_DIR/transformed"

# create dirs
if [ ! -d $WORK_DIR ];   then mkdir $WORK_DIR; fi
if [ ! -d $SOURCE_DIR ]; then mkdir $SOURCE_DIR; fi
if [ ! -d $TARGET_DIR ]; then mkdir $TARGET_DIR; fi

for i in $(eval echo {1..$THREADS}); do
    echo "thread $i";
    port="808$i"
    # start the engine
    podman run --volume /tmp/fredracor:/fredracor:z -p $port:8080 --detach existdb/existdb:latest
done

# wait for the first engine to be ready
echo "waiting for all instances to be ready…"
for i in $(eval echo {1..$THREADS}); do
    port="808$i"
    while [[ $(curl -I -s http://localhost:$port | grep -c "200 OK") -eq "0" ]] ; do
        sleep 1s
    done
    echo "$i ready."
done

# put scripts to the databases
for i in $(eval echo {1..$THREADS}); do
    port="808$i"
    for file in *.xq; do
        curl -X PUT -H 'Content-Type: application/xquery' --data-binary @$file http://admin:@localhost:$port/exist/rest/db/$file;
    done
    echo "scripts placed at instance $i"
done

# load data at first instance (shared afterwards to all others)
for file in load*.xq; do
   curl http://admin:@localhost:8081/exist/rest/db/$file
done

curl http://admin:@localhost:8081/exist/rest/db/parallelize-download-source.xq

# distribute source data to the databases

distribute () {
    instance=$1
    port="808$instance"
    echo "uploading files to instance $instance"
	for i in $(eval echo {$instance..$num..$THREADS}); do
        file=$(ls $SOURCE_DIR | head -$i | tail -1)
        if [ (($i % 50)) -eq "0" ]; then echo "$instance :: $i :: $file"; fi
        curl -X PUT -H 'Content-Type: application/xml' --data-binary @$file http://admin:@localhost:$port/exist/rest/db/data/$file;
	done
}

num=$(find $SOURCE_DIR -type f | wc -l)
cd $SOURCE_DIR
for instance in $(eval echo {1..$THREADS}); do
    distribute $instance &
done

wait

# return to git repo dir
cd $THIS_DIR

# transform source data
echo "transforming the data"

transform () {
    i=$1
    port="808$i"
    for file in transfo*.xq; do
        echo "start transformation on instance $i"
        curl http://admin:@localhost:8081/exist/rest/db/$file &
    done
}

for i in $(eval echo {1..$THREADS}); do
    transform $i &
done

wait

# get the transformed data
for instance in $(eval echo {1..$THREADS}); do
    port="808$i"
    curl http://admin:@localhost:$port/exist/rest/db/parallelize-download-target.xq &
done
wait

echo "all done."
exit 0