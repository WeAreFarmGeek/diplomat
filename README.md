# Diplomat
[![Gem Version](https://badge.fury.io/rb/diplomat.svg)](http://badge.fury.io/rb/diplomat) [![Build Status](https://travis-ci.org/WeAreFarmGeek/diplomat.svg?branch=master)](https://travis-ci.org/WeAreFarmGeek/diplomat) [![Code Climate](https://codeclimate.com/github/johnhamelink/diplomat.png)](https://codeclimate.com/github/WeAreFarmGeek/diplomat) [![Dependency Status](https://gemnasium.com/WeAreFarmGeek/diplomat.svg)](https://gemnasium.com/WeAreFarmGeek/diplomat)
### A HTTP Ruby API for [Consul](http://www.consul.io/)

![Diplomacy Boad Game](http://i.imgur.com/Nkuy4b7.jpg)


## FAQ

#### What's Diplomat for?

Diplomat allows any ruby application to interact with [Consul's](http://www.consul.io/) distributed key value store, and also receive information about services currently available in the Consul cluster.

#### Does it work in rails?

Yup! In fact, we're using it in all of our rails production apps instead of any previous case where it'd be right to use environment variables according to [12Factor configuration principals](http://12factor.net/config). This gives us the ability to scale up without making any changes to the actual project codebase, and to move applications around the cluster with ease.

Here's what a production database.yml file might look like:

```erb
<% if Rails.env.production? %>
production:
  adapter:            postgresql
  encoding:           unicode
  host:               <%= Diplomat::Service.get('postgres').Address %>
  database:           <%= Diplomat.get('project/db/name') %>
  pool:               5
  username:           <%= Diplomat.get('project/db/user') %>
  password:           <%= Diplomat.get('project/db/pass') %>
  port:               <%= Diplomat::Service.get('postgres').ServicePort %>
<% end %>
```

#### Why would I use Consul over ZooKeeper, Doozerd, etcd, Nagios, Sensu, SmartStack, SkyDNS, Chef, Puppet, Ansible, etc?

[Read up what makes Consul different here](http://www.consul.io/intro/vs/index.html)

#### How do I install Consul?

[See here](http://www.consul.io/intro/). I managed to roll it out on my production machines with the help of [Ansible](http://www.ansible.com/) in one working day.

## Usage

[The most up to date place to read about the API is here.](http://rubydoc.info/github/WeAreFarmGeek/diplomat)

Here's a few examples of how diplomat works:

### Key Values

#### Getting

Getting the value of a key in the key-value store is as simple as using one of the following:

```ruby
foo = Diplomat.get('foo')
# => "bar"
```

#### Setting

Setting the value of a key is just as easy:

```ruby
foo = Diplomat.put('foo', 'bar')
# => "bar"
```

### Services

#### Getting

Looking up a service is easy as pie:

```ruby
foo_service = Diplomat::Service.get('foo')
# => #<OpenStruct Node="hotel", Address="1.2.3.4", ServiceID="hotel_foo", ServiceName="foo", ServiceTags=["foo"], ServicePort=5432> 
```
Or if you have multiple nodes per service:

```ruby
foo_service = Diplomat::Service.get('foo', :all)
# => [#<OpenStruct Node="hotel", Address="1.2.3.4", ServiceID="hotel_foo", ServiceName="foo", ServiceTags=["foo"], ServicePort=5432>,#<OpenStruct Node="indigo", Address="1.2.3.5", ServiceID="indigo_foo", ServiceName="foo", ServiceTags=["foo"], ServicePort=5432>]
```

### Sessions

Creating a session:

```ruby
sessionid = Diplomat::Session.create({:Node => "server1", :Name => "my-lock"})
# => "fc5ca01a-c317-39ea-05e8-221da00d3a12"
```
Or destroying a session:

```ruby
Diplomat::Session.destroy("fc5ca01a-c317-39ea-05e8-221da00d3a12")
```

### Locks

Acquire a lock:

```ruby
sessionid = Diplomat::Session.create({:Node => "server1", :Name => "my-lock"})
lock_acquired = Diplomat::Lock.acquire("/key/to/lock", sessionid)
# => true
```
Or wait for a lock to be acquired:

```ruby
sessionid = Diplomat::Session.create({:hostname => "server1", :ipaddress => "4.4.4.4"})
lock_acquired = Diplomat::Lock.wait_to_acquire("/key/to/lock", sessionid)
```

Release a lock:

```ruby
Diplomat::Lock.release("/key/to/lock", sessionid )
```

### Custom configuration

You can create a custom configuration using the following syntax:

```ruby
Diplomat.configure do |config|
  # Set up a custom Consul URL
  config.url = "localhost:8888"
  # Set up a custom Faraday Middleware
  config.middleware = MyCustomMiddleware
end
```

This is traditionally kept inside the `config/initializers` directory if you're using rails. The middleware allows you to customise what happens when faraday sends and receives data. This can be useful if you want to instrument your use of diplomat, for example. You can read more about Faraday's custom middleware [here](http://stackoverflow.com/a/20973008).

### Todo

-  [ ] Updating Docs with latest changes
-  [ ] Using custom objects for response objects (instead of openStruct)
-  [ ] PUTing and DELETEing services
-  [ ] Custom SSL Cert Middleware for faraday
-  [x] Allowing the custom configuration of the consul url to connect to
-  [x] Deleting Keys
-  [x] Listing available services
-  [x] Health
-  [x] Members
-  [x] Status
-  [x] Datacenter support for services
-  [x] Ruby 1.8 support


## Enjoy!

![Photo Copyright "merlinmann". All rights reserved.](http://i.imgur.com/3mBwzR9.jpg Photo Copyright "merlinmann" https://www.flickr.com/photos/merlin/. All rights reserved.)
