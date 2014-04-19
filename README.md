# Diplomat

### A HTTP Ruby API for [Consol](http://www.consul.io/)

![Diplomacy Boad Game](http://i.imgur.com/Nkuy4b7.jpg)

#### What's Diplomat for?

Diplomat allows any ruby application to interact with [Consol's](http://www.consul.io/) distributed key value store, and also receive information about services currently available in the Consol cluster.

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

[Read up what makes Consol different here](http://www.consul.io/intro/vs/index.html)

#### How do I install Consul?

[See here](http://www.consul.io/intro/). I managed to roll it out on my production machines with the help of [Ansible](http://www.ansible.com/) in one working day.
