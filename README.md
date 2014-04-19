# Diplomat
[![Gem Version](https://badge.fury.io/rb/diplomat.svg)](http://badge.fury.io/rb/diplomat) [![Build Status](https://travis-ci.org/johnhamelink/diplomat.svg?branch=master)](https://travis-ci.org/johnhamelink/diplomat) [![Code Climate](https://codeclimate.com/github/johnhamelink/diplomat.png)](https://codeclimate.com/github/johnhamelink/diplomat)
### A HTTP Ruby API for [Consul](http://www.consul.io/)

![Diplomacy Boad Game](http://i.imgur.com/Nkuy4b7.jpg)


## FAQ

#### What's Diplomat for?

Diplomat allows any ruby application to interact with [Consul's](http://www.consul.io/) distributed key value store, and also receive information about services currently available in the Consol cluster.

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

#### Why would I use Consol over ZooKeeper, Doozerd, etcd, Nagios, Sensu, SmartStack, SkyDNS, Chef, Puppet, Ansible, etc?

[Read up what makes Consul different here](http://www.consul.io/intro/vs/index.html)

#### How do I install Consul?

[See here](http://www.consul.io/intro/). I managed to roll it out on my production machines with the help of [Ansible](http://www.ansible.com/) in one working day.

## Usage

[The most up to date place to read about the API is here.](http://rubydoc.info/github/johnhamelink/diplomat)

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
# => #<OpenStruct Node="hotel", Address="1.2.3.4", ServiceID="hotel_postgres", ServiceName="hotel_postgres", ServiceTags=["postgres"], ServicePort=5432> 
```

### Todo

 - Deleting Keys
 - Listing available Services, PUTting and DELETEing services
 - Health
 - Members
 - Status

## Enjoy!

![Photo Copyright "merlinmann". All rights reserved.](http://i.imgur.com/3mBwzR9.jpg Photo Copyright "merlinmann" https://www.flickr.com/photos/merlin/. All rights reserved.)
