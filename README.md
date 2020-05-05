openmrs-config-pihsl
==============================

### Prequistes

Some utility scripts, "install.sh" and "watch.sh", have been written to ease having to manually run mvn install
and watch commands on both this project and the "openmrs-config-pihemr" project.

However, these scripts depend on finding your "openmrs-config-pihemr" relative to this project, so they should both be 
checked out into the same directory, and the "openmrs-config-pihemr" directory should be named "openmrs-config-pihemr"
or "config-pihemr".

Example directory structure:

openmrs-config-pihemr
openmrs-config-pihsl

or

config-pihemr
config-pihsl

### Steps to deploy new changes to your local development server

Run "./install.sh [serverId]" where [serverId] is the name of the SDK server you are deploying to.  This will first build 
the config-pihemr project, then build the config-pihsl project, (pulling in any changes to config-pihemr),
and finally deploying the changes to the server specified by [serverId].

#### To enable watching, you run the following:

"./watch.sh [serverId]" where [serverId] is the name of the SDK server you are deploying too.  This will watch
*both* the config-pihemr and config-pihsl projects for changes and redeploy when there are changes.  It runs
indefinitely, so you will need to cancel it with a "Ctrl-C".


### General usage

`mvn clean compile` - Will generate your configurations into "target/openmrs-packager-config/configuration"
`mvn clean package` - Will compile as above, and generate a zip package at "target/${artifactId}-${version}.zip"

In order to facilitate deploying configurations easily into an OpenMRS SDK server, one can add an additional parameter
to either of the above commands to specify that the compiled configuration should also be copied to an existing 
OpenMRS SDK server:

`mvn clean compile -DserverId=pihsl` - Will compile as above, and copy the resulting configuration to `~/openmrs/pihsl/configuration`

If the configuration package you are building will be depended upon by another configuration package, you must "install" it
in order for the other package to be able to pick it up.

`mvn clean install` - Will compile and package as above, and install as an available dependency on your system

For more details regarding the available commands please see:
https://github.com/openmrs/openmrs-contrib-packager-maven-plugin 
