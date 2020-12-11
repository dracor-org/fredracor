#!/bin/bash
# this script is used to load and convert the source corpus
# with parallel processors. it uses podman, but MAY BE it
# works with docker as well

# read parameters
debug="" # enables debug mode with option --debug

while [ -n "$1" ]; do
    case "$1" in
    --help) echo "FreDraCor conversion. loads, transforms and validates results in parallel processes. \
                OPTIONS: \
                --debug     run only on a few files and less parallel threads\
                --progress  enable a progress bar"; exit 0; ;;
    --debug) debug="true"; echo "DEBUG MODE ENABLED" ;;
    --progress) progress="true" ;;
    *) echo "Unknown option passed." exit 1;
    esac
    shift
done;

if [ ! -z $debug ]; then
    # take only a few files in debug mode
    THREADS=2 # usually more than 7 threads create a slight overhead
else
    THREADS=6 # usually more than 7 threads create a slight overhead
fi

PORTPREFIX="644"

CONTAINER=() # put container ids here, to stop them afterwards

THIS_DIR="$PWD"
WORK_DIR="/tmp/fredracor"
SOURCE_DIR="$WORK_DIR/data"
TARGET_DIR="$WORK_DIR/transformed"

START=$(date +'%T')
echo $START

# interrupt
# get log from container
log () {
    date=$(date +'%F')
    for c in ${CONTAINER[@]}; do
        podman logs $c >> report-$date-$START.log
        cp report-$date-$START.log report-latest.log
    done
}

stopContainer () {
    # remove container
    for c in ${CONTAINER[@]}; do
        echo "stopping container $c"
        podman stop $c
    done
}

# watch progress
# TODO: move to inotify
progress () {
    current=0
    echo
    if [ ! -z $progress ]
    then
        curl --silent --output $WORK_DIR/progressbar.sh https://raw.githubusercontent.com/roddhjav/progressbar/v1.1/progressbar.sh
        source $WORK_DIR/progressbar.sh || exit 2
        until [ $current -eq $num ]; do
            current=$(ls $TARGET_DIR | wc -l)
            progressbar "Transformation" $current $num
            sleep 1s
        done
    else
        until [ $current -eq $num ]; do
            current=$(ls $TARGET_DIR | wc -l)
            echo -n "\r$current / $num"
            sleep 1s
        done
        echo
    fi
}

trap 'echo "SIGINT received! Terminating…"; log; stopContainer;' SIGINT SIGTERM

# create dirs
if [ ! -d $WORK_DIR ]; then mkdir $WORK_DIR; fi
if [ ! -d $SOURCE_DIR ];
    then mkdir $SOURCE_DIR; 
    else
        echo "SOURCE_DIR found with $(ls $SOURCE_DIR | wc -l) items."
        read -p "Do you want to reload source? [Y/n] " reload

fi
if [ ! -d $TARGET_DIR ]
    then mkdir $TARGET_DIR;
    else
        echo "TARGET_DIR found with $(ls $TARGET_DIR | wc -l) items."
        read -p "Do you want to remove the previouse transformation results? [Y/n] " retransform
        if [[ $retransform != "n" ]]; then echo "removing previouse results…"; rm -f $TARGET_DIR/*.xml; fi 
fi

for instance in $(eval echo {1..$THREADS}); do
    echo "thread $instance"
    port="$PORTPREFIX$instance" 
    # start the engine
    CONTAINER_ID=$(podman run --volume /tmp/fredracor:/fredracor:z -p $port:8080 --detach existdb/existdb:latest)
    CONTAINER+=($CONTAINER_ID)
    echo "container id: $CONTAINER_ID"
done

echo ${CONTAINER[*]} > $WORK_DIR/container

# wait for the first engine to be ready
# about 3 minutes for 6 instances
echo "waiting for all instances to be ready…"
for i in $(eval echo {1..$THREADS}); do
    port="$PORTPREFIX$i"
    while [[ $(curl -I -s http://localhost:$port | grep -c "200 OK") -eq "0" ]] ; do
        sleep 1s
    done
    echo "$i ready."
done

echo "$(date +'%T') :: ready"

# put scripts to the databases
for i in $(eval echo {1..$THREADS}); do
    port="$PORTPREFIX$i"
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
        curl --silent --output report-load.log http://admin:@localhost:${PORTPREFIX}1/exist/rest/db/$file
    done
fi

echo "load source data to volume, remove from instance 1 afterwards"
if [[ $reload != "n" ]]; then
    curl --silent "http://admin:@localhost:${PORTPREFIX}1/exist/rest/db/parallelize-download-source.xq"
    curl --silent --output "$WORK_DIR/tei_all.rng" "http://admin:@localhost:${PORTPREFIX}1/exist/rest/db/tei_all.rng"
    curl --silent --output "$WORK_DIR/ids.xml" "http://admin:@localhost:${PORTPREFIX}1/exist/rest/db/ids.xml" &&
    cp $WORK_DIR/ids.xml $THIS_DIR/ids.xml # save the new list of ids in the repo
fi
echo "$(date +'%T') :: load data done"

numSourceFiles=$(ls $SOURCE_DIR | wc -l)
echo "$(date +'%T') :: received $numSourceFiles files"

# distribute source data to the databases
# about 3 minutes
distribute () {
    instance=$1
    port="$PORTPREFIX$instance"
    echo "uploading files to instance $instance"
	for i in $(eval echo {$instance..$num..$THREADS}); do
        if [ ! -z $debug ]; then
            # take the smallest files in debug mode
            file=$(ls -Sr $SOURCE_DIR | head -$i | tail -1)
        else
            # alphanumeric order
            file=$(ls $SOURCE_DIR | head -$i | tail -1)
        fi
        curl -X PUT -H 'Content-Type: application/xml' --data-binary @$file http://admin:@localhost:$port/exist/rest/db/data/$file;
	done
    # add tei_all.rng to the db
    filename="tei_all.rng"
    file="$WORK_DIR/$filename"
    curl -X PUT -H 'Content-Type: application/xml' --data-binary @$file http://admin:@localhost:$port/exist/rest/db/$filename;
    filename="ids.xml"
    file="$WORK_DIR/$filename"
    curl -X PUT -H 'Content-Type: application/xml' --data-binary @$file http://admin:@localhost:$port/exist/rest/db/$filename;
}

if [ ! -z $debug ]; then
    # take only a few files in debug mode
    num=33
else
    num=$numSourceFiles
fi

cd $SOURCE_DIR
for instance in $(eval echo {1..$THREADS}); do
    distribute $instance &
done

wait

echo "$(date +'%T') :: distribution done"

# return to git repo dir
cd $THIS_DIR

# transform source data
# about 50 minutes
echo "transforming the data"

transform () {
    i=$1
    port="$PORTPREFIX$i"
    for file in transfo*.xq; do
        echo "start transformation on instance $i"
        curl --silent http://admin:@localhost:$port/exist/rest/db/$file > /dev/null
    done
}

for i in $(eval echo {1..$THREADS}); do
    transform $i &
done

progress &

wait > /dev/null

echo "$(date +'%T') :: transformation done."

# import new files to THIS repo
cp $TARGET_DIR/*.xml $THIS_DIR/tei/

# terminate
log
stopContainer

echo "$(date +'%T') :: all done"

if [ "$(ls -A $TARGET_DIR)" ]; then
    countTargets=$(ls $TARGET_DIR/*.xml | wc -l)
    echo "$(date +'%T') :: successfully created fredracor with $countTargets items."
    valid="$(grep -c "✔ tei_all" report-latest.log)"
    echo "$(date +'%T') :: ✔ $valid valid tei_all documents prepared"
    invalid="$(grep -c "✘ tei_all" report-latest.log)"
    echo "$(date +'%T') :: ✘ $invalid invalid tei_all documents found"
    jingmessages="$(grep -c "/message" report-latest.log)"
    echo "$(date +'%T') :: $jingmessages messages reported by jing."
fi

exit 0