# Changelog

## Unreleased
 - 2017-01-23 Trevor Wood <trevor.g.wood@gmail.com> Add key/value store transaction API endpoint
 - 2017-02-15 Paul Thomas <paul+github@paulthomas.eu> Allow events to target another datacenter
 - 2017-01-23 Adam Wentz <adam@adamwentz.com> Defend against newlines added to responses in dev mode where pretty-printing is enabled by default.
 - 2017-04-07 Zane Williamson <sepulworld@gmail.com> Add cluster status API endpoint

## 1.2.0
 - 2017-01-22 Trevor Wood <trevor.g.wood@gmail.com> RuboCop fixes and add RuboCop checks
 - 2017-01-17 Trevor Wood <trevor.g.wood@gmail.com> Add cross DC sessions and locking
 - 2017-01-11 Dylan Vassallo <dylanvassallo@gmail.com> Include Consul errors in Diplomat::UnknownStatus messages
 - 2017-01-04 Trevor Wood <trevor.g.wood@gmail.com> Add Diplomat::Query API endpoint
 - 2016-12-15 Trevor Wood <trevor.g.wood@gmail.com> Diplomat::Health returns hashes instead of OpenStructs

## 1.1.0
 - 2016-08-09 Stefan Merettig <stefan-merettig@nuriaproject.org> Add .respond_to? and .respond_to_missing? to Diplomat::RestClient
 - 2016-09-21 Dana Pieluszczak <dana@greenhouse.io> Add recurse option to Kv#delete
 - 2016-10-24 Ryan Duffield <rduffield@pagerduty.com> Add tag option to Health#service
 - 2016-11-05 Trevor Wood <trevor.g.wood@gmail.com> Diplomat::Node.get returns a hash instead of an OpenStruct

## 0.19.0, 1.0.0
 - 2016-08-02 John Hamelink <john@johnhamelink.com> Improve ACL and Event endpoints by uniformly raising an error for statuscodes which aren't 200.
 - 2016-08-02 Sandstrom <alexander@skovik.com> Add documentation for listing all keys
 - 2016-08-02 Alexander Vagin <laplugin73@gmail.com> Add state option to Health service
 - 2016-08-02 John Hamelink <john@johnhamelink.com> Removed Ruby 1.x support. Added check to raise error for ruby versions <
 - 2016-07-27 Kendrick Martin <kmartinix@gmail.com> Added the ability to return k/v data as ruby hash

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
