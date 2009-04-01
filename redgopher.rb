#!/usr/local/bin/ruby
# I have an idea, lets use a pure OO langauge with closures and other neat things to write
# a procedural program for dumb terminals, yeah!

require 'socket'
require 'tempfile'
$types ={
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

pager="less"
pagermode=0

def parseurl(url)
  opts=url.sub('gopher://','').split('/') # split the url by slashes
  host=opts.shift # the first element will be our host
  type=opts.shift # type is second
  if !$types.has_key?(type) then # check to see if a type was provided
    opts.unshift(type) # if not, then its part of the path, put it back
    puts "No type given, assuming 1" # tell them the error of their ways
    type="1" # and assume its a directory
  end
  path = opts.first.nil? ? '/' :  opts.join('/') # if no path is provided, we go to the root
  [host,type,path] # return it!
end
  
host,type,path=parseurl(ARGV[0] || 'robsayers.com' ) 


history=[]
input=""

puts %{
**************Red Gopher****************
*  Simple Client for simple terminals  *
*                By:                   *
*   Rob Sayers rsayers@robsayers.com   *
****************************************}
while input!="quit" do
  begin
    # getaddrinfo fails immediately,  saving us from waiting for the socket connect to timeout
    Socket.getaddrinfo(host,70)
    t = TCPSocket.new(host,70)
    t.puts path
  rescue
    puts "Error connecting to "+host
  end
  history << [host,path,type] # so we can go back later
  case type
  when "0"

    # pagermode will write the data to a temp file, then pipe it through less
    # if pager mode is not on, it will not save anything, I'm considering 
    # forcing it anyhow for caching... good idea?

    if pagermode == 1 then
      fp=Tempfile.new('redgopher')  
      fp.puts t.read
      fp.close
      system pager +" "+fp.path
      fp.unlink
    else
      puts t.read
    end
  when "1"
    lines = t.readlines
    res=[]
    count=1
    fp=Tempfile.new('redgopher') if pagermode==1
    lines.each do |l|
      linedata = l.split("\t")
      linetype=l[0]
      desc=linedata[0][1,linedata[0].length-1]
      if type=='i' || $types[linetype].nil?
        if pagermode==1 then 
          fp.puts desc
        else
          puts desc
        end
      else
        if pagermode==1 then
          fp.puts count.to_s+". ["+$types[linetype]+"] "+desc
        else
          puts count.to_s+". ["+$types[linetype]+"] "+desc
        end
        res[count]=[linedata[2],linedata[1],linetype]
        count+=1
      end
    end
    fp.close if pagermode==1
    system pager +" "+fp.path if pagermode==1
  else # if its not a dir or text file, prompt to save
    # i will eventually have handlers for at least html and telnet
    # maybe even more
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
    history.pop unless history.length==1 # remove the last item unless there is only 1(the current url)
    host,path,type = history.pop # remove the current url
  elsif input == "r"
    path="/"
    type="1"
  elsif input =="p"
    if pagermode==0
      pagermode=1
      puts "Turning on page mode"
    else
      pagermode=0
      puts "Turning off page mode"
    end
    
  elsif input == ""
    # do nothing
  else
    
    host,type,path=parseurl(input)
    
  end
end


