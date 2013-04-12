require 'net/http'

$check_website_status = ['http://media.ecg-berlin.de/', 'http://www.ecg-berlin.de/', 'http://kinderarche-berlin.de/']

def check_web()
    $check_website_status.each do |u|
        res = Net::HTTP.get_response(URI(u))
        if(res.class.name != 'Net::HTTPOK') 
            error("#{u} is not online. Error code #{res.code}")
        end
    end
end

def error(s)
    puts s
end
check_web();
