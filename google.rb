require 'google-search'

Google::Search::Web.new(:query => 'Cookies', :rsz => 5).each do |image|
	puts image.uri;
end
