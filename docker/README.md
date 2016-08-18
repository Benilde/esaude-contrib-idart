<br/><br/><br/>
<img src="https://s3-eu-west-1.amazonaws.com/esaude/images/esaude-site-header.png" alt="eSaude"/>
<br/><br/><br/>

# eSaude iDart Docker

[![Build Status](https://travis-ci.org/esaude/esaude-contrib-idart.svg?branch=master)](https://travis-ci.org/esaude/esaude-contrib-idart)
[![Download](https://api.bintray.com/packages/esaude/idart-docker/java/images/download.svg) ](https://bintray.com/esaude/idart-docker/java/_latestVersion)
[![eSaude Slack](https://slack.esaude.org/badge.svg)](https://slack.esaude.org)

This repository contains the necessary infrastructure code and related resources
required to compose and run Docker containers that start an instance of the
eSaude fork of the iDart application. For more information about iDart see the
[project README](../README.md).

Also included is a Docker compose file that starts up all the services required
to demonstrate the integration between iDart and the eSaude EMR Platform.

## Prerequisites

Make sure you have [Docker](https://docs.docker.com/) and
[Docker Compose](https://docs.docker.com/compose/install/) installed.

## Running iDart

> **:bulb: Ubuntu users must first run `xhost local:root` to enable X11 forwarding**

On Linux you should just be able to run:

```sh
docker-compose -f docker-compose-idart-prebuilt.yml up
```

or if you want to build your own images:

```sh
docker-compose -f docker-compose-idart.yml up
```

#### Login details

 * User: **admin**
 * Pass: **123**

Read below for more information and instructions for macOS. See the next section
for instructions for running the complete iDart eSaude Platform integration.

### X11 Forwarding

iDart is a desktop application developed using the SWT user interface framework.
As such, it needs a way to render the application GUI. Since Docker containers
are headless, we do this by using X11 forwarding.

When you run the containers, the iDart application will run in the Docker container,
and the GUI will be rendered using native SWT bindings in the container, but will be
displayed on your host machine by forwarding to the X11 server running on your
host.

This forwarding mechanism is configured using the `DISPLAY` environment variable as well as the `/tmp/.X11-unix` data volume.

In Linux the `DISPLAY` variable should already be set up for you, so you shouldn't have
to do anything to make it work. If you are on Ubuntu you will probably need to
run `xhost local:root` to give the `root` user access to the X11 socket.

On macOS, you'll need [XQuartz](http://xquartz.macosforge.org/landing/) and [socat](http://linux.die.net/man/1/socat) installed (`brew install socat`).

Run XQuarts, then create a socket redirect as follows:

```sh
socat TCP-LISTEN:6000,reuseaddr,fork UNIX-CLIENT:\"$DISPLAY\"
```

You'll then need to set the `DISPLAY` variable to your IP address on the `vboxnet0`
interface:

```sh
export DISPLAY=192.168.99.1:0
```

Note the extra `:0` at the end.

You can find this IP address as follows:

```
ifconfig vboxnet0 | grep 'inet' | cut -d' ' -f2
```


## Running iDart Platform Integration

> **:bulb: Ubuntu users must first run `xhost local:root` to enable X11 forwarding**

Set up the complete iDart eSaude Platform integration by running:

```sh
docker-compose -f docker-compose-idart-platform-integration-prebuilt.yml up
```

or if you want to build your own images:

```sh
docker-compose -f docker-compose-idart-platform-integration.yml up
```

:pushpin: Make sure you have no existing platform containers running.

#### Login details

 * User: **admin**
 * Pass: **123**

## Building

> :bulb: To build iDart you need to use Java 6.

Running the [`build-docker-images.sh`](build-docker-images.sh) script in this directory
will build iDart, but to build it manually, run the following in the project root:

```sh
ant clean build prepareLibs jar -Ddatabase.name=idart -Ddatabase.host=idart-postgres
```

If you are not building iDart in order to create new Docker images, you can change
the values of the database properties as required. Additional properties can
configured in [`clean_idart.properties`](../clean_idart.properties) or in
[`build.properties`](../build.properties).

Note that property values specified on the commandline will always override those
specified in `.properties` files.

### Build Properties

iDart uses two main properties files, `idart.properties` and [`jdbc.properties`](../src/jdbc.properties).
The main `idart.properties` file (in the project root) is generated at build time by using [`clean_idart.properties`](../clean_idart.properties)
as a base and populating it with the values specified in [`build.properties`](../build.properties)
(or with properties specified as commandline parameters, as in the case of the Docker build).

The `jdbc.properties` file (counterintuitively) contains the OpenMRS REST
details (host, user & pass) that are used by iDart for integration with the eSaude
EMR Platform.

When building the iDart Docker images, please make sure that [`jdbc.properties`](../src/jdbc.properties)
contains contains the following:

```properties
urlBase=http://esaude-emr-tomcat:8080/openmrs/ws/rest/v1/
userName=admin
password=eSaude123
```

The following database properties should exist in `build.properties`
when building iDart in preparation for building the Docker images:

```properties
database.username=postgres
database.password=postgres
database.url=jdbc:postgresql://${database.host}:5432/${database.name}
```

The following properties are specified on the commandline by the [`build-docker-images.sh`](build-docker-images.sh)
script:

```properties
database.name=idart
database.host=idart-postgres
```

## Troubleshooting

If your OpenMRS REST details are not configured correctly the application will
likely throw an exception and crash.

:warning: Creating prescriptions, then dispensing and posting to OpenMRS does not
work unless you have `v2.9` (I think) of the OpenMRS REST Web Services module
installed. This is due to [this line](https://github.com/esaude/esaude-contrib-idart/blob/master/src/org/celllife/idart/gui/packaging/NewPatientPackaging.java#L2827) which expects a very specific response
from OpenMRS. This response has been changed to be more correct in more recent
versions of the REST module.

## License

[MPL 2.0 w/ HD](http://openmrs.org/license/)
