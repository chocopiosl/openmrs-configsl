#!/bin/bash

# if there's a "config-pihemr" or "openmrs-config-pihemr" directory at the same level as this project,
# run a pull there as well

if [[ -d '../config-pihemr' ]]; then
    (cd ../config-pihemr && git pull)
elif [[ -d '../openmrs-config-pihemr' ]]; then
    (cd ../openmrs-config-pihemr && git pull)
else
  echo "Unable to find PIH-EMR config, skipping pulling it"
fi

git pull
