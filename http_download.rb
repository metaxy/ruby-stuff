#encoding: UTF-8
require 'nokogiri'
require 'httparty'
require 'fileutils'
require 'cgi'
require 'optparse'

def main()
    url = nil
    path = "./"
    optparse = OptionParser.new do|opts|
        opts.banner = "Usage: download_http.rb [options]"
        opts.on('--url URl', 'Which Site to download. Must end with /' ) do |x|
            url = x
        end
        opts.on('--path PATH', 'Where to download. Must end with /' ) do |x|
            path  = x
        end
        opts.on( '-h', '--help', 'Display this screen' ) do
            puts opts
            exit
        end
    end.parse!
    if url.nil?
        puts "missing --url"
        exit
    end
    scan(url, path); 
end

def scan(url, path)
    puts "scan url #{url}"
    FileUtils.mkpath(path)
    uri = URI(url)

    response = Net::HTTP.get(uri).force_encoding('UTF-8')
    doc = Nokogiri::HTML(response)
    l = doc.css('a').map { |link| link['href'] }
    
    l.each do |link|
        next if link.start_with? "/"
        next if link.start_with? "?"
        next if link.start_with? ".."
        if(is_file? link) 
            download_file(url+link,path+CGI::unescape(link)) 
        else

            scan(url+link, path+CGI::unescape(link))
        end
    end
end

def is_file?(url)
    not url.end_with? "/"
end

def download_file(url, path)
    if File.exists? path
        puts "skipping: #{path} exists"
        return
    end
    puts "downloading… #{CGI::unescape(url)}"
    `curl "#{url}" -o "#{path}"` 
end

main()
