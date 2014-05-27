#!/usr/bin/env ruby

require 'socket'
require 'sqlite3'
require 'digest/sha1'

# Daemonize current process
Process.daemon File.dirname(Process.argv0)

# Variables
HOST = '0.0.0.0'
PORT = 34567
DB = "#{File.dirname(Process.argv0)}/db.sqlite3"
BIND_ZONE = '/etc/bind/example.com'

# Code part 
if !File.exists?(DB)
  db = SQLite3::Database.new( DB )
  begin
    db.execute( "create table accounts (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, key varchar(32) UNIQUE, ip varchar(15), domain varchar(100) UNIQUE, zone_rec_name varchar(100) UNIQUE, update_at timestamp DEFAULT CURRENT_TIMESTAMP);" )
  rescue Exception => e
    puts e.message
    puts e.backtrace
  end
else
  db = SQLite3::Database.new( DB )
end

def key_exists?(db, key)
  begin
    result = db.prepare("select count(*) from accounts where key like ?").execute( key )
  rescue SQLite3::Exception => e 
    puts "Exception occured"
    puts e
  end  
  result.each do |raw|
    if raw[0].to_i > 0 
      return true 
    else 
      return false 
    end
  end
end

sock = TCPServer.new(HOST, PORT)
loop do
  Thread.start(sock.accept) do |client|
    key = client.gets.chomp 
    if /[a-z0-9]{32}/.match(key)
      if key_exists?(db, key)
        port, ip = Socket.unpack_sockaddr_in(client.getpeername)
        db.prepare('update accounts set ip=? where key like ?').execute(ip, key)
        client.write 'saved'
      end
    end
    client.close
  end
end
