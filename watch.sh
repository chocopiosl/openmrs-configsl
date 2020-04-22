#!/bin/bash

usage () {
    echo -e "Usage: watch.sh [SERVER]\n"
    echo -e "Watches the configuration and updates SERVER on any chances, where a server is the name of an OpenMRS SDK instance at path '~/openmrs/[SERVER]'\n"
    echo -e "Also watches the parent config if it is at ../openmrs-config-pihemr or ../config-pihemr.\n"
    echo -e "Example: ./watch.sh mirebalais\n"
}

mvn_watch() {
  mvn clean openmrs-packager:watch -DdelaySeconds=1
}

if [ $# -eq 0 ]; then
    echo -e "Please provide the name of the server to install to as a command line argument.\n"
    usage
    exit 1
fi


# if there's a "config-pihemr" or "openmrs-config-pihemr" directory at the same level as this project,
# run the watch for it as well
if [[ -d '../config-pihemr' ]]; then
    (cd ../config-pihemr && mvn_watch &)
elif [[ -d '../openmrs-config-pihemr' ]]; then
    (cd ../openmrs-config-pihemr && mvn_watch &)
else
  echo "Unable to find PIH-EMR config, skipping watching it"
fi

mvn clean openmrs-packager:watch -DserverId=$1 -DdelaySeconds=1
