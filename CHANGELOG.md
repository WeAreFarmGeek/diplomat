# Changelog

## 2.0.0
- 2017-07-28 Eugen Mayer [eugen.mayer@kontextwork.de][35] Do not set the adapter on faraday prior the request (#149)
- 2017-07-21 Ben Wu [wucheokman@gmail.com][34] fix single key/value in Diplomat::Kv.get with convert_to_hash option ON (#147)
- 2017-04-26 Trevor Wood [trevor.g.wood@gmail.com][1] Add service maintenance API call

## 1.3.0
 - 2017-01-23 Trevor Wood [trevor.g.wood@gmail.com][2] Add key/value store transaction API endpoint
 - 2017-02-15 Paul Thomas [paul+github@paulthomas.eu][3] Allow events to target another datacenter
 - 2017-01-23 Adam Wentz [adam@adamwentz.com][4] Defend against newlines added to responses in dev mode where pretty-printing is enabled by default.
 - 2017-04-07 Zane Williamson [sepulworld@gmail.com][5] Add cluster status API endpoint

## 1.2.0
 - 2017-01-22 Trevor Wood [trevor.g.wood@gmail.com][6] RuboCop fixes and add RuboCop checks
 - 2017-01-17 Trevor Wood [trevor.g.wood@gmail.com][7] Add cross DC sessions and locking
 - 2017-01-11 Dylan Vassallo [dylanvassallo@gmail.com][8] Include Consul errors in Diplomat::UnknownStatus messages
 - 2017-01-04 Trevor Wood [trevor.g.wood@gmail.com][9] Add Diplomat::Query API endpoint
 - 2016-12-15 Trevor Wood [trevor.g.wood@gmail.com][10] Diplomat::Health returns hashes instead of OpenStructs

## 1.1.0
 - 2016-08-09 Stefan Merettig [stefan-merettig@nuriaproject.org][11] Add .respond\_to? and .respond\_to\_missing? to Diplomat::RestClient
 - 2016-09-21 Dana Pieluszczak [dana@greenhouse.io][12] Add recurse option to Kv#delete
 - 2016-10-24 Ryan Duffield [rduffield@pagerduty.com][13] Add tag option to Health#service
 - 2016-11-05 Trevor Wood [trevor.g.wood@gmail.com][14] Diplomat::Node.get returns a hash instead of an OpenStruct

## 0.19.0, 1.0.0
 - 2016-08-02 John Hamelink [john@johnhamelink.com][15] Improve ACL and Event endpoints by uniformly raising an error for statuscodes which aren't 200.
 - 2016-08-02 Sandstrom [alexander@skovik.com][16] Add documentation for listing all keys
 - 2016-08-02 Alexander Vagin [laplugin73@gmail.com][17] Add state option to Health service
 - 2016-08-02 John Hamelink [john@johnhamelink.com][18] Removed Ruby 1.x support. Added check to raise error for ruby versions \<
 - 2016-07-27 Kendrick Martin [kmartinix@gmail.com][19] Added the ability to return k/v data as ruby hash

## 0.18.0

 - 2016-05-24 Jiri Fajfr [jiri.fajfr@ncr.com][20] Added Support for ACL in Node, Service and Event
 - 2016-05-24 Aaron Brown [aaronbbrown@github.com][21] Added Diplomat::Maintenance class with #enable and #enabled? methods.
 - 2016-05-03 Joshua Delsman [jdelsman@usertesting.com][22] Added ability to register/deregister nodes

## 0.17.0

 - 2016-04-27 Ryan Schlesinger [ryan@outstand.com][23] Added external service registration
 - 2016-04-27 Improvements to ACL info method when the ACL doesn't exist

## 0.16.2

 - 2016-04-13 Grégoire Seux [g.seux@criteo.com][24] Refactor HTTP deserialization to allow for raw responses to deserialize properly.
 - 2016-04-13 Add the ACL token, if configured, to `lock` calls

## 0.16.1

 - 2016-04-13 John Hamelink [john@johnhamelink.com][25] Fix license in Gemspec

## 0.16.0

 - 2016-04-07 michlyon [michlyon@twitch.tv][26] Add ability to get all nodes across a datacenter
 - 2016-03-26 Tony Nyurkin [tnyurkin@libertyglobal.com][27] Add tests for healthchecking the datacenter
 - 2016-01-27 Sam Marx [smarx@spredfast.com][28] Add a datacenter option to the healthchecker
 - 2015-12-01 Morgan Larosa [chaos95@gmail.com][29] Add support for datacenter argument in Service#get\_all

## 0.15.0

 - 2015-11-19 Michael Miko [michael.setiawan@rakuten.com][30] Add options to get ModifyIndex value
 - 2015-11-12 Grégoire Seux [g.seux@criteo.com][31] Add specs for ACL management, improve ACL management code
 - 2015-07-25 r.hanna [r.hanna@criteo.com][32] Add ACL support

[1]:	mailto:trevor.g.wood@gmail.com
[2]:	mailto:trevor.g.wood@gmail.com
[3]:	mailto:paul+github@paulthomas.eu
[4]:	mailto:adam@adamwentz.com
[5]:	mailto:sepulworld@gmail.com
[6]:	mailto:trevor.g.wood@gmail.com
[7]:	mailto:trevor.g.wood@gmail.com
[8]:	mailto:dylanvassallo@gmail.com
[9]:	mailto:trevor.g.wood@gmail.com
[10]:	mailto:trevor.g.wood@gmail.com
[11]:	mailto:stefan-merettig@nuriaproject.org
[12]:	mailto:dana@greenhouse.io
[13]:	mailto:rduffield@pagerduty.com
[14]:	mailto:trevor.g.wood@gmail.com
[15]:	mailto:john@johnhamelink.com
[16]:	mailto:alexander@skovik.com
[17]:	mailto:laplugin73@gmail.com
[18]:	mailto:john@johnhamelink.com
[19]:	mailto:kmartinix@gmail.com
[20]:	mailto:jiri.fajfr@ncr.com
[21]:	mailto:aaronbbrown@github.com
[22]:	mailto:jdelsman@usertesting.com
[23]:	mailto:ryan@outstand.com
[24]:	mailto:g.seux@criteo.com
[25]:	mailto:john@johnhamelink.com
[26]:	mailto:michlyon@twitch.tv
[27]:	mailto:tnyurkin@libertyglobal.com
[28]:	mailto:smarx@spredfast.com
[29]:	mailto:chaos95@gmail.com
[30]:	mailto:michael.setiawan@rakuten.com
[31]:	mailto:g.seux@criteo.com
[32]:	mailto:r.hanna@criteo.com
[33]: mailto:miguel.parramon@kantox.com
[34]: mailto:wucheokman@gmail.com
[35]: mailto:eugen.mayer@kontextwork.de
