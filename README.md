# Diplomat
[![Gem Version](https://badge.fury.io/rb/diplomat.svg)](http://badge.fury.io/rb/diplomat) [![Build Status](https://travis-ci.org/WeAreFarmGeek/diplomat.svg?branch=master)](https://travis-ci.org/WeAreFarmGeek/diplomat) [![Code Climate](https://codeclimate.com/github/johnhamelink/diplomat.png)](https://codeclimate.com/github/WeAreFarmGeek/diplomat) [![Dependency Status](https://gemnasium.com/WeAreFarmGeek/diplomat.svg)](https://gemnasium.com/WeAreFarmGeek/diplomat) [![Inline docs](http://inch-ci.org/github/wearefarmgeek/diplomat.svg?branch=master)](http://inch-ci.org/github/wearefarmgeek/diplomat)
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

Check out [Travis](https://travis-ci.org/WeAreFarmGeek/diplomat) to see which versions of ruby we currently test when we're making builds.

We've dropped ruby 1.9 support. You can still depend on Diplomat by directly using the `ruby-1.9-compatible` branch on github, although be advised it's not actively maintained anymore.

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
  # Connect into consul with custom access token (ACL)
  config.acl_token =  "xxxxxxxx-yyyy-zzzz-1111-222222222222"
  # Set extra Faraday configuration options
  config.options = {ssl: { version: :TLSv1_2 }}
end
```

This is traditionally kept inside the `config/initializers` directory if you're using rails. The middleware allows you to customise what happens when faraday sends and receives data. This can be useful if you want to instrument your use of diplomat, for example. You can read more about Faraday's custom middleware [here](http://stackoverflow.com/a/20973008).

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
