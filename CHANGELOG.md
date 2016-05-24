# Changelog

## Unreleased

## 0.18.0

 - 2016-05-24 Jiri Fajfr <jiri.fajfr@ncr.com> Added Support for ACL in Node, Service and Event
 - 2016-05-24 Aaron Brown <aaronbbrown@github.com> Added Diplomat::Maintenance class with #enable and #enabled? methods.
 - 2016-05-03 Joshua Delsman <jdelsman@usertesting.com> Added ability to register/deregister nodes

## 0.17.0

 - 2016-04-27 Ryan Schlesinger <ryan@outstand.com> Added external service registration
 - 2016-04-27 Improvements to ACL info method when the ACL doesn't exist
 
## 0.16.2

 - 2016-04-13 Grégoire Seux <g.seux@criteo.com> Refactor HTTP deserialization to allow for raw responses to deserialize properly.
 - 2016-04-13 Add the ACL token, if configured, to `lock` calls

## 0.16.1

 - 2016-04-13 John Hamelink <john@johnhamelink.com> Fix license in Gemspec

## 0.16.0

 - 2016-04-07 michlyon <michlyon@twitch.tv> Add ability to get all nodes across a datacenter
 - 2016-03-26 Tony Nyurkin <tnyurkin@libertyglobal.com> Add tests for healthchecking the datacenter
 - 2016-01-27 Sam Marx <smarx@spredfast.com> Add a datacenter option to the healthchecker
 - 2015-12-01 Morgan Larosa <chaos95@gmail.com> Add support for datacenter argument in Service#get_all

## 0.15.0

 - 2015-11-19 Michael Miko <michael.setiawan@rakuten.com> Add options to get ModifyIndex value
 - 2015-11-12 Grégoire Seux <g.seux@criteo.com> Add specs for ACL management, improve ACL management code
 - 2015-07-25 r.hanna <r.hanna@criteo.com> Add ACL support
