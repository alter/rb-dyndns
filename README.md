rb-dyndns
=========

ruby analog of dyndns


This is software complex from 2 applications:
1. TCP Server which gets request for update from clients and updates IPs in sqlite database.
2. Bind zone updater which gets records from sqlite database, updates A zones and serials in zone file and makes "rndc reload"

= Installation =
== Preparations == 
0. use ruby >= 2.1 ( Set it from RVM )
1. git clone git@github.com:alter/rb-dyndns.git /opt/rb-dyndns/
2. edit rb-dyndns.rb
# Variables
HOST = '0.0.0.0'
PORT = 34567
DB = "#{File.dirname(Process.argv0)}/db.sqlite3"
BIND_ZONE = '/etc/bind/example.com'

HOST - address which listens by rb-dyndns.rb
POST - port which listens by rb-dyndns.rb
DB - this construction detects where rb-dyndns.rb places and gets folder name, after concatenates it with db name "db.sqlite3"
BIND_ZONE - file with DNS zone

3. add A record for your zone, for example:
test A 127.0.0.1

4. be sure that serial field has own row in the file and comment "; serial", for example:
2014052807; serial

5. start rb-dyndns.rb, it'll create db.sqlite3 in the same folder.
This db contains simple table with following fields:
id, key, ip, domain, zone_rec_name, updated_at
You have to insert records for hosts which uses dynamic addresses, for example:
insert into accounts(key, ip, domain, zone_rec_name) values ('098f6bcd4621d373cade4e832627b4f6', '127.0.0.1', 'test.com', 'test');

key - must have following format [a-z0-9]{32} (just generate md5sum from random phrase).

6. edit zone_updater.rb
# Variables
DB = "#{File.dirname(Process.argv0)}/db.sqlite3"
BIND_ZONE = '/etc/bind/itsb.pro'

DB - should be the same as for rb-dyndns.rb
BIND_ZONE - should be the same as for rb-dyndns.rb

== Start ==
1. chmod +x rb-dyndns.rb
2. ./rb-dyndns.rb
3. add runs of zone_updater.rb in the crontab:
*/30  * * * * bind  /opt/rb-dyndns/zone_updater.rb

== Client ==
On the client side set in crontab:
*/10   * * * * user  echo -n '$KEY' | nc $HOST $PORT &> /dev/null
where $HOST and $PORT of server( the same as in rb-dyndns.rb )

=== Advices for better security ===
chown -R bind.bind /etc/bind
chown -R bind.bind /opt/rb-dyndns

Run all scripts from bind user:
/usr/bin/sudo -u bind /opt/rb-dyndns/rb-dyndns.rb
/usr/bin/sudo -u bind /opt/rb-dyndns/zone_updater.rb

== Known issues ==
If you have problems with running scripts from bind user under rvm, just read https://rvm.io/integration/cron
