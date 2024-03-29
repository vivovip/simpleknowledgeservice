#!/bin/bash
echo
APACHE_JENA_FUSEKI_DIR=$(ls -t -U | grep -m 1 "^apache-jena-fuseki")
if [[ -z $APACHE_JENA_FUSEKI_DIR ]]; then
    echo "No 'apache-jena-fuseki*' subdirectory. Please download jena. Exiting ..."
    exit 1
fi
# Adding Jena to classpath
CP=".:$APACHE_JENA_FUSEKI_DIR/fuseki-server.jar"
DBLOC=sksdb
mkdir -p $DBLOC
echo "On $(date +%Y/%m/%d), creating/clearing '${DBLOC}' and (re)loading schemes ..."
if [ "$(ls -A $DBLOC)" ]; then
    echo "Clearing current contents of database location '$DBLOC'"
    rm $DBLOC/*
fi
SCHEMESDIR="../schemes"
SCHEMEZIPS="$SCHEMESDIR/*zip"
ZIPRE='\/([A-Z0-9]+)_([^\.]+)\.zip$'
# Before loading schemes, ensure only one version for each scheme ...
SCHEMEMNSEEN=""
for szip in $SCHEMEZIPS; do
    if [[ $(echo $szip) =~ $ZIPRE ]]; then
        SCHEMEMN=${BASH_REMATCH[1]}
        if [[ $SCHEMEMNSEEN =~ $SCHEMEMN ]]; then
            echo
            echo "More than one $SCHEMEMN version in $SCHEMESDIR - not allowed. Exiting ..."
            exit 1
        fi
        SCHEMEMNSEEN="$SCHEMEMNSEEN $SCHEMEMN"
    fi
done
if [[ -z $SCHEMEMNSEEN ]]; then
    echo
    echo "No schemes available in $SCHEMESDIR - you should download some. Exiting ..."
    exit 1
fi
for szip in $SCHEMEZIPS; do
    if [[ $(echo $szip) =~ $ZIPRE ]]; then
        SCHEMEMN=${BASH_REMATCH[1]}
        VERSION=${BASH_REMATCH[2]}
        GRAPHID="http://schemes.caregraf.info/$(tr [A-Z] [a-z] <<< "$SCHEMEMN")"
        echo 
        echo "Loading ${SCHEMEMN}, version ${VERSION} into <${GRAPHID}> ..."
        for i in {1..80}
        do
            echo -n '-'
        done
        echo
        TTLINZIP="${SCHEMEMN}_${VERSION}/scheme.ttl"
        unzip -p $szip $TTLINZIP | java -cp $CP riotcmd.turtle --output nquads | java -cp $CP tdb.tdbloader --loc $DBLOC --graph $GRAPHID -- -
    fi
echo
done
echo
