#!/bin/bash
# this script is used to load and convert the source corpus
# with parallel processors. it uses podman, but MAY BE it
# works with docker as well

THREADS=3
CONTAINER=() # put container ids here, to stop them afterwards

THIS_DIR="$PWD"
WORK_DIR="/tmp/fredracor"
SOURCE_DIR="$WORK_DIR/data"
TARGET_DIR="$WORK_DIR/transformed"

START=$(date +"%T")
echo $START

# create dirs
if [ ! -d $WORK_DIR ];   then mkdir $WORK_DIR; fi
if [ ! -d $SOURCE_DIR ];
    then mkdir $SOURCE_DIR; 
    else
        echo "SOURCE_DIR found with $(ls $SOURCE_DIR | wc -l) items."
        read -p "Do you want to reload source? [y/n]" reload
fi
if [ ! -d $TARGET_DIR ]; then mkdir $TARGET_DIR; fi

for i in $(eval echo {1..$THREADS}); do
    echo "thread $i";
    port="808$i"
    # start the engine
    CONTAINER_ID=$(podman run --volume /tmp/fredracor:/fredracor:z -p $port:8080 --detach existdb/existdb:latest)
    CONTAINER+=(CONTAINER_ID)
done

# wait for the first engine to be ready
# about 3 minutes for 6 instances
echo "waiting for all instances to be ready…"
for i in $(eval echo {1..$THREADS}); do
    port="808$i"
    while [[ $(curl -I -s http://localhost:$port | grep -c "200 OK") -eq "0" ]] ; do
        sleep 1s
    done
    echo "$i ready."
done

echo "$(date +"%T") :: ready"

# put scripts to the databases
for i in $(eval echo {1..$THREADS}); do
    port="808$i"
    for file in *.xq; do
        curl -X PUT -H 'Content-Type: application/xquery' --data-binary @$file http://admin:@localhost:$port/exist/rest/db/$file;
    done
    echo "scripts placed at instance $i"
done

# load data at first instance, shared to all others afterwards
# about 15 minutes
if [[ $reload != "n" ]]; then
    echo "load data on instance 1"
    for file in load*.xq; do
        curl --silent --output report-load.log http://admin:@localhost:8081/exist/rest/db/$file
    done
fi

echo "load source data to volume, remove from instance 1 afterwards"
curl "http://admin:@localhost:8081/exist/rest/db/parallelize-download-source.xq"
echo "$(date +"%T") :: load data"

# distribute source data to the databases
# about 3 minutes
distribute () {
    instance=$1
    port="808$instance"
    echo "uploading files to instance $instance"
	for i in $(eval echo {$instance..$num..$THREADS}); do
        file=$(ls $SOURCE_DIR | head -$i | tail -1)
        curl -X PUT -H 'Content-Type: application/xml' --data-binary @$file http://admin:@localhost:$port/exist/rest/db/data/$file;
	done
}

num=$(find $SOURCE_DIR -type f | wc -l)
cd $SOURCE_DIR
for instance in $(eval echo {1..$THREADS}); do
    distribute $instance &
done

wait
echo "$(date +"%T") :: distribute"

# return to git repo dir
cd $THIS_DIR

# transform source data
# about 50 minutes
echo "transforming the data"

transform () {
    i=$1
    port="808$i"
    for file in transfo*.xq; do
        echo "start transformation on instance $i"
        curl http://admin:@localhost:$port/exist/rest/db/$file
    done
}

for i in $(eval echo {1..$THREADS}); do
    transform $i &
done

wait
echo "$(date +"%T") :: transform"

# get the transformed data
for instance in $(eval echo {1..$THREADS}); do
    port="808$instance"
    curl http://admin:@localhost:$port/exist/rest/db/parallelize-download-target.xq &
done
wait

# import new files to THIS repo
cp $TARGET_DIR/*.xml $THIS_DIR/tei/

# get log from container
date=$(date +"%F")
for c in $CONTAINER; do
    podman logs $c >> $date-report.log
done


# remove container
for c in $CONTAINER; do
    echo "stopping container $c"
    podman stop $c
done

echo "$(date +"%T") :: all done"
exit 0