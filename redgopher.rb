#!/usr/local/bin/ruby

require 'socket'

types ={
  "0"=>"TXT",
  "1"=>"DIR",
  "2"=>"CSO",
  "3"=>"ERR",
  "4"=>"HEX",
  "5"=>"ARC",
  "6"=>"UUE",
  "7"=>"QUE",
  "8"=>"TEL",
  "9"=>"BIN",
  "g"=>"GFX",
  "h"=>"HTM",
  "s"=>"AUD"
}


opts=ARGV[0] ? ARGV[0].split('/') : ["robsayers.com","1","/"]
host = opts.shift || 'robsayers.com'
type = opts.shift 

if !types.has_key?(type) then
  opts.unshift(type)
  puts "No type given, assuming 1"
  type="1"
end

path = opts.join('/') || '/'

history=[]
helpscreen=0
input=""
while input!="quit" do
  
  begin
    t = TCPSocket.new(host,70)
    t.puts path
  rescue
    puts "Error connecting to "+host
  end
  
  history << [host,path,type]
  case type
  when "0"
      puts t.read
  when "1"
    lines = t.readlines
    res=[]
      count=1
    lines.each do |l|
        linedata = l.split("\t")
        type=l[0]
        desc=linedata[0][1,linedata[0].length-1]
        if type=='i' || types[type].nil?
          puts desc
          
        else
          puts count.to_s+". ["+types[type]+"] "+desc
          res[count]=[linedata[2],linedata[1],type]
          count+=1
        end
      end
    else 
      if types.has_key?(type) then
        filename = path.split('/').last
        print "Save File? (y/n)"
        input = STDIN.readline.strip
        if input == "y" then
          print "Filename? "
          input = STDIN.readline.strip
          puts "Saving file, please wait..."
          open(input,"w").print(t.read)
          puts "Done!"
        end
      else
        puts "Unknown Type"
      end
    end
  print ">"
  input = STDIN.readline.strip
  exit if input == "quit" 
  if input.to_i > 0 then
    if res[input.to_i].nil? then
      puts "No such item"
    else
      host=res[input.to_i][0]
      path=res[input.to_i][1]
      type=res[input.to_i][2]
    end
  elsif input == "b"
    history.pop unless history.length==1
    host,path,type = history.pop
  elsif input == "r"
    path="/"
    type="1"
  elsif input == ""
    # do nothing
  else
    type="1"
    host=input
    path="/"
  end
end


