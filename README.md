# Diplomat
[![Build Status](https://github.com/WeAreFarmGeek/diplomat/workflows/Ruby/badge.svg?branch=master)](https://github.com/WeAreFarmGeek/diplomat/actions?query=branch%3Amaster)
[![Gem Version](https://badge.fury.io/rb/diplomat.svg)](https://rubygems.org/gems/diplomat) [![Gem](https://img.shields.io/gem/dt/diplomat.svg)](https://rubygems.org/gems/diplomat) [![Code Climate](https://codeclimate.com/github/johnhamelink/diplomat.svg)](https://codeclimate.com/github/WeAreFarmGeek/diplomat) [![Inline docs](http://inch-ci.org/github/wearefarmgeek/diplomat.svg?branch=master)](http://inch-ci.org/github/wearefarmgeek/diplomat)
### A HTTP Ruby API for [Consul](http://www.consul.io/)

![Diplomacy Board Game](http://i.imgur.com/Nkuy4b7.jpg)


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
  database:           <%= Diplomat::Kv.get('project/db/name') %>
  pool:               5
  username:           <%= Diplomat::Kv.get('project/db/user') %>
  password:           <%= Diplomat::Kv.get('project/db/pass') %>
  port:               <%= Diplomat::Service.get('postgres').ServicePort %>
<% end %>
```

#### Why would I use Consul over ZooKeeper, Doozerd, etcd, Nagios, Sensu, SmartStack, SkyDNS, Chef, Puppet, Ansible, etc?

[Read up what makes Consul different here](http://www.consul.io/intro/vs/index.html)

#### How do I install Consul?

[See here](http://www.consul.io/intro/). I managed to roll it out on my production machines with the help of [Ansible](http://www.ansible.com/) in one working day.

### Which versions of Ruby does Diplomat support? Where did my ruby 1.9 compatibility go?

Check out [GitHub Actions](https://github.com/WeAreFarmGeek/diplomat/blob/master/.github/workflows/ruby.yml) to see which versions of ruby we currently test when we're making builds.

We've dropped ruby 1.9 support. You can still depend on Diplomat by directly using the `ruby-1.9-compatible` branch on github, although be advised it's not actively maintained anymore.

### ERB templating

It is possible to inject diplomat data into `.erb` files (such as in chef), but you could also have a look at
[consul-templaterb](https://github.com/criteo/consul-templaterb/) that is highly optimized for ERB templating
with very hi parallelism and good optimized performance for large clusters.

## Usage

[The most up to date place to read about the API is here.](http://rubydoc.info/github/WeAreFarmGeek/diplomat)

Here's a few examples of how diplomat works:

### Key Values

#### Setting

Setting the value of a key is easy as pie:

```ruby
foo = Diplomat::Kv.put('foo', 'bar')
# => "bar"
```

#### Getting

Getting the value of a key is just as simple:

```ruby
foo = Diplomat::Kv.get('foo')
# => "bar"
```

Or retrieve a value from another datacenter:

```ruby
foo = Diplomat::Kv.get('foo', :dc => 'dc-west')
# => "baz"
```

You can also retrieve values recursively:

```ruby
Diplomat::Kv.put('foo/a', 'lorem')
Diplomat::Kv.put('foo/b', 'ipsum')
Diplomat::Kv.put('foo/c', 'dolor')

Diplomat::Kv.get('foo/', recurse: true)
# => [{:key=>"foo/a", :value=>"lorem"}, {:key=>"foo/b", :value=>"ipsum"}, {:key=>"foo/c", :value=>"dolor"}]
```

You can also use `get_all` to retrieve values recursively with a consistent return type:

```ruby
Diplomat::Kv.put('foo/a', 'lorem')
Diplomat::Kv.put('foo/b', 'ipsum')
Diplomat::Kv.put('foo/c', 'dolor')

Diplomat::Kv.get('foo/', recurse: true)
# => [{:key=>"foo/a", :value=>"lorem"}, {:key=>"foo/b", :value=>"ipsum"}, {:key=>"foo/c", :value=>"dolor"}]
Diplomat::Kv.get_all('foo/')
# => [{:key=>"foo/a", :value=>"lorem"}, {:key=>"foo/b", :value=>"ipsum"}, {:key=>"foo/c", :value=>"dolor"}]

Diplomat::Kv.put('bar/a', 'lorem')

Diplomat::Kv.get('bar/', recurse: true)
# => "lorem"
Diplomat::Kv.get_all('bar/')
# => [{:key=>"bar/a", :value=>"lorem"}]
```


Or list all available keys:

```ruby
Diplomat::Kv.get('/', :keys => true) # => ['foo/a', 'foo/b']
```
You can convert the consul data to a ruby hash

```ruby
Diplomat::Kv.put('foo/a', 'lorem')
Diplomat::Kv.put('foo/b', 'ipsum')
Diplomat::Kv.put('foo/c', 'dolor')

Diplomat::Kv.get('foo/', recurse: true, convert_to_hash: true)
# => {"foo"=>{"a"=>"lorem", "b"=>"ipsum", "c"=>"dolor"}}
```

### Nodes

#### Getting

Look up a node:

```ruby
foo_service = Diplomat::Node.get('foo')
# => {"Node"=>{"Node"=>"foobar", "Address"=>"10.1.10.12"}, "Services"=>{"consul"=>{"ID"=>"consul", "Service"=>"consul", "Tags"=>nil, "Port"=>8300}, "redis"=>{"ID"=>"redis", "Service"=>"redis", "Tags"=>["v1"], "Port"=>8000}}}
```

Get all nodes:

```ruby
nodes = Diplomat::Node.get_all
# => [#<OpenStruct Address="10.1.10.12", Node="foo">, #<OpenStruct Address="10.1.10.13", Node="bar">]
```

Get all nodes for a particular datacenter

```ruby
nodes = Diplomat::Node.get_all({ :dc => 'My_Datacenter' })
# => [#<OpenStruct Address="10.1.10.12", Node="foo">, #<OpenStruct Address="10.1.10.13", Node="bar">]
```

Register a node:

```ruby
Diplomat::Node.register({ :Node => "app1", :Address => "10.0.0.2" })
# => true
```

De-register a node:

```ruby
Diplomat::Node.deregister({ :Node => "app1", :Address => "10.0.0.2" })
# => true
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

Or if you want to find services for a particular datacenter

```ruby
foo_service = Diplomat::Service.get('foo', :all, { :dc => 'My_Datacenter'})
# => [#<OpenStruct Node="hotel", Address="1.2.3.4", ServiceID="hotel_foo", ServiceName="foo", ServiceTags=["foo"], ServicePort=5432>,#<OpenStruct Node="indigo", Address="1.2.3.5", ServiceID="indigo_foo", ServiceName="foo", ServiceTags=["foo"], ServicePort=5432>]
```

Or if you want to filter services

```ruby
foo_service = Diplomat::Service.get('foo', :all, { :filter => 'ServiceID == "indigo_foo"'})
# => [#<OpenStruct Node="indigo", Address="1.2.3.5", ServiceID="indigo_foo", ServiceName="foo", ServiceTags=["foo"], ServicePort=5432>]
```

If you wish to list all the services on consul:

```ruby
services = Diplomat::Service.get_all
# => #<OpenStruct consul=[], foo=[], bar=[]>
```

If you wish to list all the services for a specific datacenter:

```ruby
services = Diplomat::Service.get_all({ :dc => 'My_Datacenter' })
# => #<OpenStruct consul=[], foo=[], bar=[]>
```

### Datacenters

Getting a list of datacenters is quite simple and gives you the option to extract all services out of
all accessible datacenters if you need to.

```ruby
datacenters = Diplomat::Datacenter.get()
# => ["DC1", "DC2"]
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

Renew a session:
```ruby
Diplomat::Session.renew(sessionid)
```

List sessions:
```ruby
Diplomat::Session.list.each {|session| puts "#{session["ID"]} #{session["Name"]}"}
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

### Events

Fire an event:

```ruby
Diplomat::Event.fire('do_something', 'payload')
```

List all events with a certain name received by the local agent:

```ruby
Diplomat::Event.get_all('do_something')
```

Get the latest event with a certain name received by the local agent:

```ruby
Diplomat::Event.get('do_something')
```

Iterate through the events with a certain name received by the local agent:

```ruby
events = Enumerator.new do |y|
  ret = {token: :first}
  while ret = begin Diplomat::Event.get('do_something', ret[:token], :reject) rescue nil end
    y.yield(ret[:value])
  end
end

events.each{ |e| puts e }
```

### Status

Returns information about the status of the Consul cluster.

Get the raft leader for the datacenter in which the local consul agent is running

```ruby
Diplomat::Status.leader()
```

Get an array of Raft peers for the datacenter in which the agent is running

```ruby
Diplomat::Status.peers()
```

### Autopilot

Returns information about the autopilot configuration of the Consul cluster

Get the current autopilot configuration

```ruby
Diplomat::Autopilot.get_configuration()
```

Get the health status from autopilot

```ruby
Diplomat::Autopilot.get_health()
```

### Health

Retrieve health of a node

```ruby
Diplomat::Health.node('fooNode', :dc => 'abc')
```

Retrieve health of a given check

```ruby
Diplomat::Health.checks('fooCheck', :dc => 'abc')
```

Retrieve health of a given service

```ruby
Diplomat::Health.service('fooService', :dc => 'abc')
```

Retrieve a list of anything that correspond to the state ("any", "passing", "warning", or "critical")
You can use filters too !

```ruby
Diplomat::Health.state("critical", {:dc => 'abc', :filter => 'Node==foo'})
```

You also have some convenience method (`any`, `passing`, `warning`, `critical`)
That can be filtered

```ruby
Diplomat::Health.critical({:dc => 'abc', :filter => 'ServiceName==foo'})
```

### Maintenance mode

Enable maintenance mode on a host, with optional reason and DC (requires access to local agent)

```ruby
Diplomat::Maintenance.enable(true, 'doing stuff', :dc => 'abc')
```

Determine if a host has maintenance mode enabled

```ruby
Diplomat::Maintenance.enabled('foobar')
# => { :enabled => true, :reason => 'doing stuff' }
```

### Custom configuration

You can create a custom configuration using the following syntax:

```ruby
Diplomat.configure do |config|
  # Set up a custom Consul URL
  config.url = "http://localhost:8888"
  # Set up a custom Faraday Middleware
  config.middleware = MyCustomMiddleware
  # Set extra Faraday configuration options and custom access token (ACL)
  config.options = {ssl: {version: :TLSv1_2}, headers: {"X-Consul-Token" => "xxxxxxxx-yyyy-zzzz-1111-222222222222"}}
end
```

This is traditionally kept inside the `config/initializers` directory if you're using rails. The middleware allows you to customise what happens when faraday sends and receives data. This can be useful if you want to instrument your use of diplomat, for example. You can read more about Faraday's custom middleware [here](http://stackoverflow.com/a/20973008).

Alternatively, configuration settings can be overriden at each method call allowing for instance to address different consul agents, with some other token.

```ruby
Diplomat::Service.get('foo', { http_addr: 'http://consu01:8500' })
Diplomat::Service.get('foo', { http_addr: 'http://consu02:8500' })
Diplomat::Kv.put('key/path', 'value', { http_addr: 'http://localhost:8500', dc: 'dc1', token: '111-222-333-444-555' })
```

Most common options are:
* dc: target datacenter
* token: identity used to perform the corresponding action
* http_addr: to target a remote consul node
* stale: use consistency mode that allows any server to service the read regardless of whether it is the leader

### Todo

-  [ ] Updating Docs with latest changes
-  [ ] Using custom objects for response objects (instead of openStruct)
-  [ ] PUTing and DELETEing services
-  [x] Custom SSL Cert Middleware for faraday
-  [x] Allowing the custom configuration of the consul url to connect to
-  [x] Deleting Keys
-  [x] Listing available services
-  [x] Health
-  [x] Members
-  [x] Status
-  [x] Datacenter support for services
-  [x] Ruby 1.8 support
-  [x] Events


## Enjoy!

![Photo Copyright "merlinmann" https://www.flickr.com/photos/merlin/. All rights reserved.](http://i.imgur.com/3mBwzR9.jpg)
