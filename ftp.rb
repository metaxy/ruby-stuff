 require 'optparse'
 require 'net/ftp'

 # This hash will hold all of the options
 # parsed from the command-line by
 # OptionParser.
 $options = {}
 optparse = OptionParser.new do|opts|
   # Set a banner, displayed at the top
   # of the help screen.
   opts.banner = "Usage: ftp.rb [options]"

 
   $options[:server] = nil
   opts.on( '-s', '--server SERVERNAME', 'Which server to connect' ) do |file|
     $options[:server] = file
   end
   $options[:username] = "anonymous"
   opts.on( '-u', '--username USERNAME', 'Usernme' ) do |file|
     $options[:username] = file
   end
   $options[:password] = nil
   opts.on( '-p', '--password PASSWORD', 'Password' ) do |file|
     $options[:password] = file
   end
   
   $options[:include] = Array.new
   opts.on( '-i', '--include FILETYPE', 'Include files' ) do |file|
     $options[:include] << file
   end
   
   $options[:exclude] = Array.new
   opts.on( '-e', '--exclude FILETYPE', 'Exclude files' ) do |file|
     $options[:exclude] << file
   end
   
   $options[:path] = "/"
   opts.on( '-f', '--folder PATH', 'Path on the server' ) do |file|
     $options[:path] = file
   end
   
   $options[:dest] = nil
   opts.on( '-d', '--dest PATH', 'Path on your computer' ) do |file|
     $options[:dest] = file
   end
   # This displays the help screen, all programs are
   # assumed to have this option.
   opts.on( '-h', '--help', 'Display this screen' ) do
     puts opts
     exit
   end
 end
 
 # Parse the command-line. Remember there are two forms
 # of the parse method. The 'parse' method simply parses
 # ARGV, while the 'parse!' method parses ARGV and removes
 # any options found there, as well as any parameters for
 # the options. What's left is the list of files to resize.
optparse.parse!

def changeDir(dir)
    if FileTest::directory?(dir)
        return
    end
    Dir::mkdir(dir)
    Dir.chdir dir
end
def downloadR()
    files = $ftp.list('*')
    files.each do |f|
        fileName = f.split(/\s+/).last
        if(f[0, 1] == "d")
            $ftp.chdir(fileName)
            changeDir(fileName)
            downloadR()
        else
            ok = true;
            if(not $options[:exclude].empty?)
                 if(not fileName =~ /#{$options[:exclude]}$/ )
                     ok = true
                 else
                     ok = false
                 end
           elsif(not $options[:include].empty?)
                 if(fileName =~ /#{$options[:include]}$/ )
                     ok = true
                 else
                     ok = false
                 end
            end
            if ok
                puts "downloading " + fileName; 
                $ftp.getbinaryfile(fileName)
            end
        end
    end
    $ftp.chdir("../")
    Dir.chdir ("../")
end


def main()
    if($options[:server] == nil)
        puts "need server argument"
        return
    end
    if($options[:dest] != nil)
        if not FileTest::directory?($options[:dest])
            Dir::mkdir($options[:dest])
        end
        Dir.chdir $options[:dest]
    end
    
    $ftp = Net::FTP.new($options[:server])
    $ftp.passive = true
    $ftp.login($options[:username],$options[:password])
    $ftp.chdir($options[:path])
    downloadR();
    $ftp.close

end
main()
