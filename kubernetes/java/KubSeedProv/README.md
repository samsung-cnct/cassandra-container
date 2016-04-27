# Cassandra Java Build
4/26/2016 mikeln

## Overview

* Update version in `pom.xml`.  (`pom.xml.template`: `<groupId>%%PACKAGE%%</groupId>` shows the location).
* Run `mvn package` to build the `target/<name version>.jar`
* Copy the `target/<name version>.jar` to the `../../cassandra` directory.
* Update the `Makefile` in `../../cassandra` for the new `<name version>.jar` and `version`
* `git add` the new `<name version>.jar` in the `../../cassandra` directory.

