require 'optparse'
require 'rubygems'
require 'taglib'
require 'find'
require 'net/scp'
require 'net/ssh'
require 'date'
require 'net/http'
require 'json'
require 'uri'

# cat to path
$catNames = Hash[
        "hellersdorf-predigt" => "Predigt",
        "lichtenberg-predigt" => "Predigt",
        "wartenberg-predigt" => "Predigt",
        "spandau-predigt" => "Predigt",
        "hellersdorf-gemeindeseminar" => "Gemeindeseminar",
        "hellersdorf-jugend" => "Jugend",
        "lichtenberg-jugend" => "Jugend",
        "wartenberg-jugend" => "Jugend",
        "spandau-jugend" => "Jugend"]
$paths = Hash[
        "hellersdorf-predigt" => "downloads/hellersdorf/predigt",
        "lichtenberg-predigt" => "downloads/lichtenberg/predigt",
        "wartenberg-predigt" => "downloads/wartenberg/predigt",
        "spandau-predigt" => "downloads/spandau/predigt",
        "hellersdorf-gemeindeseminar" => "downloads/hellersdorf/gemeindeseminar",
        "hellersdorf-jugend" => "downloads/hellersdorf/jugend",
        "lichtenberg-jugend" => "downloads/lichtenberg/jugend",
        "wartenberg-jugend" => "downloads/wartenberg/jugend",
        "spandau-jugend" => "downloads/spandau/jugend"]
$host = "5.9.58.75";
$username = "git_lightplanke";
$api = "http://media.ecg-berlin.de/components/com_sermonspeaker/api/get.php?"
$home = "/var/www/vhosts/ecg-berlin.de/media/"

$options = {}
optparse = OptionParser.new do|opts|
   opts.banner = "Usage: ftp.rb [options]"
 
   $options[:files] = []
   opts.on( '-f', '--files FILENAMES', 'Which files to upload' ) do |file|
     $options[:files] << file
   end
   $options[:title] = nil
   opts.on( '-t', '--title TITLE', 'Title' ) do |file|
     $options[:title] = file
   end
   $options[:preacher] = nil
   opts.on( '-p', '--preacher PREACHER', 'Preacher' ) do |file|
     $options[:preacher] = file
   end
   
   $options[:cat] = Array.new
   opts.on( '-c', '--cat FILETYPE', 'Include files' ) do |file|
     $options[:cat] = file
   end
   
   $options[:lang] = nil
   opts.on( '-l', '--lang FILETYPE', 'Exclude files' ) do |file|
     $options[:lang] = file
   end
   
   $options[:ref] = 
   opts.on( '-r', '--ref PATH', 'Path on the server' ) do |file|
     $options[:ref] = file
   end
   
    $options[:date] = nil
    opts.on( '-d', '--date DATUM', 'Aufnahmedatum' ) do |file|
        $options[:date] = file
    end


    $options[:serie] = nil
    opts.on( '-s', '--serie PATH', 'Path on your computer' ) do |file|
        $options[:serie] = file
    end

    $options[:key] = "~/.ssh/id_rsa"
    opts.on( '-k', '--key PATH', 'Path to your keyfile.' ) do |file|
        $options[:key] = file
    end


   # This displays the help screen, all programs are
   # assumed to have this option.
    opts.on( '-h', '--help', 'Display this screen' ) do
        puts opts
        exit
    end
end.parse!

def writeid3(file)
   frame_factory = TagLib::ID3v2::FrameFactory.instance
   frame_factory.default_text_encoding = TagLib::String::UTF8
    TagLib::MPEG::File.open(file) do |file|
        tag = file.id3v2_tag
        tag.album = $options[:serie]
        tag.year = Date.parse($options[:date]).year
        tag.comment = "Aufnahme der ECG Berlin http://ecg-berlin.de"
        tag.artist = $options[:preacher]
     #   tag.date = $options[:date]
     #   tag.language = $options[:lang]
        tag.title = $options[:title]
        file.save
    end

end

def upload(file, ssh)
    puts "audio.rb :::: Uploading ...";
    mainPath = $paths[$options[:cat]]
    ext = File.extname(file)
    
    mainPath << "/" + (case ext
                when ".mp3"
                    "audio"
                when ".mp4"
                    "video"
                else
                    "extra" end)
    mainPath << "/" << Date.parse($options[:date]).year.to_s + "/"
    ssh.scp.upload!(file, $home + mainPath, :chunk_size => 2048 * 32);
    return (mainPath + File.basename(file))
end
def near(res, name)
    puts "audio.rb :::: got resp " + res;
    json = JSON.parse(res)
    json.each do |x|
        if(name == x[0])
            return x[0]
        end
    end
    json.each do |x|
        if(name == x[2])
            return x[0]
        end
    end
    json.each do |x|
        if(name == x[1])
            return x[0]
        end
    end

    return "0"
end
def getSpeakerID(name)
    res = Net::HTTP.get URI($api + "action=list_speakers")
    return near(res,name)
end

def getSeriesID(name)
    res = Net::HTTP.get URI($api + "action=list_series")
    return near(res,name)
end

def getCatID(name)
    res = Net::HTTP.get URI($api + "action=list_cats")
    return near(res,name)
end


def register(newPaths, ssh)
    speaker_id = getSpeakerID($options[:preacher])
    series_id = getSeriesID($options[:serie])
    cat_id = getCatID($options[:cat])

    audiofile = ""
    videofile = ""
    addfile = ""
    newPaths.each do |x|
        ext = File.extname(x)
        case ext
            when ".mp3"
                audiofile = x
            when ".mp4"
                videofile = x
            else
                addfile = x
        end
    end
    data = Hash["speaker_id" => speaker_id,
                'series_id' => series_id,
                'audiofile' => audiofile,
                'videofile' => videofile,
                'sermon_title' => $options[:title],
                'alias' => $options[:title],
                'addfile' => addfile,
                'addfileDesc' => "Notizen",
                'catid' => cat_id,
                'language' => '*',
                'sermon_date' => $options[:date],
                'sermon_time' => ""
             ]
    j = data.to_json.to_s
    # puts "audio.rb :::: json = " + j
    puts ssh.exec!("echo '" + j + "' > #{$home}data.txt");
    puts ssh.exec!("php #{$home}components/com_sermonspeaker/api/insert.php");
end
def rename(old)
    newName = old
    if(File.extname(old) == ".mp3")
        cat = $catNames[$options[:cat]]
        ref = ""
        ref = " " + ref + " " if $options[:ref] != ""
        newName = "#{$options[:date]} #{cat} - #{ref}#{$options[:title]} (#{$options[:preacher]}).mp3"
        File.rename(old, newName)
    end
    newName
end
def main()
    newPaths = []
    Net::SSH.start( $host, 
                     $username, 
                     :auth_methods => ['publickey','password'], 
                     :keys => [$options[:key]]
                   ) do |ssh|
        $options[:files].each do |x|
            puts "audio.tb :::: processing filename = " + x
            newName = rename(x)
            writeid3(newName) if File.extname(newName) == ".mp3"
            newPaths << upload(newName, ssh)
        end
        register(newPaths,ssh)
    end

end
main()

