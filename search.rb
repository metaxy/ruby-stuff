require 'mechanize'
require 'term/ansicolor' #gem install term-ansicolor
include Term::ANSIColor

def main()
    $agent = Mechanize.new
    $agent.user_agent_alias = 'Mac Safari'
    name = ARGV[0]
    puts "Suchterm = #{name}"
    search_betanien name
    search_ebtc name
    search_clv name
    search_lichtzeichen name
    #search_posaunenruf name
    search_samenkorn name
end

def search_betanien(name)
    page = $agent.get "http://www.cbuch.de/advanced_search_result.php?keywords=#{name}"
    links = parse_site(page, "td.main a")
    print_links links
end

def search_ebtc(name)
    page = $agent.get "http://www.ebtc-media.org/catalogsearch/result/?q=#{name}"
    links = parse_site(page, "h2.product-name a")
    print_links links
end

def search_clv(name)
    page = $agent.get "http://clv.de/index.php?cl=search&searchparam=#{name}"
    links = Hash.new
    page.parser.css("div.titleBox > a").each do |link|
        if insert_ok?(links, link["href"], link["title"])
            links[link["href"]] = link["title"]
        end
    end
    print_links links
end

def search_lichtzeichen(name)
    page = $agent.get "http://lichtzeichen-shop.com/index.php?cl=search&searchparam=#{name}"
    links = Hash.new
    page.parser.css("div.info > a").each do |link|
        if insert_ok?(links, link["href"], link["title"])
            links[link["href"]] = link["title"]
        end
    end
    print_links links
end

def search_posaunenruf(name)
    page = $agent.get "http://www.posaunenruf.org/index.php?tpl=&_artperpage=100&cl=search&searchparam=#{name}"
    links = Hash.new
    pp page
    page.parser.css(".h3 > a").each do |link|
        links[link["href"]] = link.text
    end
    print_links links
end

def search_samenkorn(name)
    page = $agent.get "http://www.cvsamenkorn.de/epages/62617714.sf/de_DE/?ViewAction=FacetedSearchProducts&ObjectPath=/Shops/62617714&SearchString=#{name}&PageSize=50&Page=1"
    links = Hash.new
    page.parser.css("a.ProductName").each do |link|
        if insert_ok?(links, link["href"], link["title"])
            links[link["href"]] = link["title"]
        end
    end
    
    links2 = Hash.new
    links.each do |x,y|
        links2["http://www.cvsamenkorn.de/epages/62617714.sf/de_DE/"+x] = y
    end
    print_links links2
end

def insert_ok?(struct, id, new)
    return struct[id] == nil || struct[id].size < new.size
end

def parse_site(page, css)
    links = Hash.new
    page.parser.css(css).each do |link|
        if insert_ok?(links, link["href"], link.text)
            links[link["href"]] = link.text
        end
    end
    return links
   
end

def print_links(links)
    links.each do |x,y|
        print red, bold, y, reset, " - " ,x, "\n"
    end
end

main()
