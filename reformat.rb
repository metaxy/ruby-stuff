# encoding: utf-8
#
def main()
    fileName = ARGV[0]
    puts fileName
    puts "a \u00AD b"
    out = ""
    File.open(fileName).each do |line|
	if(line["\n"] != nil)
	    line["\n"] = " "
	end
	if(out[out.size() - 2] =="\u00AD")
	    out.chop!.chop!
	    puts "chop"
	end
	out += line
    end
    File.open(fileName + '_', 'w') { |file| file.write(out) }
end
main()
