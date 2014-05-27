#!/usr/bin/env ruby 

require 'sqlite3'

# Variables
DB = "#{File.dirname(Process.argv0)}/db.sqlite3"
BIND_ZONE = '/etc/bind/example.com'

# Code part
if !File.exists?(DB)
  puts "DB doesn't exists, run server.rb"
  exit 1
else
  db = SQLite3::Database.new( DB )
end

def update_bind_zone(zone_rec_name, ip)
  # update record
  cmd = "sed -i -r -e 's/(#{zone_rec_name}\\s+A\\s+)(.*)/\\1#{ip}/' #{BIND_ZONE}"
  %x[ #{cmd} ]

  #update serial
  date = %x[ date "+%Y%m%d" ]
  cmd = "egrep -i serial #{BIND_ZONE} |egrep -o -e '[0-9]+' | cut -c 9-"
  serial = %x[ #{cmd} ]
  serial = serial.to_i + 1
  if serial.to_s.length == 1
    serial = "0#{serial}"
  end
  new_serial = "#{date.chomp}#{serial.chomp}"
  cmd = "sed -i -r -e 's/([0-9]+)(\\s*;\\s*serial*)/#{new_serial}\\2/' #{BIND_ZONE}"
  %x[ #{cmd} ]
end

def get_zone_rec_name(db)
  for_update = {}
  begin
    result = db.prepare("select zone_rec_name, ip from accounts").execute()
  rescue SQLite3::Exception => e 
    puts "Exception occured"
    puts e
  end  
  result.each do |raw|
    zone_rec_name, ip = raw
    for_update[zone_rec_name] = ip
  end
  return for_update
end
  

for_update = get_zone_rec_name(db)
for_update.each do |zone_rec_name, ip|
  update_bind_zone(zone_rec_name, ip)
end

%x[ rndc reload ]
