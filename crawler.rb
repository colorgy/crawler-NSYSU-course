require 'nokogiri'
require 'pry'
require 'json'
require 'rest-client'

courses = []
# 13 - 19: 一 - 日
days = %w(一 二 三 四 五 六 日)
# 一B8,三34

(1..115).each do |page_number|

	string = nil

	if File.exist?("1031/#{page_number}.html")
		string = File.read("1031/#{page_number}.html")
	else
		url = "https://selcrs.nsysu.edu.tw/menu1/dplycourse.asp?a=1&D0=1031&D1=&D2=&CLASS_COD=&T3=&teacher=&crsname=&WKDAY=3&SECT=&SECT_COD=&ALL=&CB1=&SPEC=&HIS=2&IDNO=&ITEM=&TYP=1&bottom_per_page=10&data_per_page=20&page=#{page_number}"

		string = (RestClient.get url).to_s
		File.open("1031/#{page_number}.html", 'w') {|f| f.write(string)}
	end
	document = Nokogiri::HTML(string)

	document.css('html table tr:nth-child(n+4)').each do |row|
		datas = row.css("td")

		result = []
		datas[13..19] && datas[13..19].each_with_index{|x, i| result << "#{days[i]}#{x.text}" if not x.text.gsub(/\ +/,'').empty? }
		periods = result.join(',')

		courses << {
			year: datas[0] && datas[0].text,
			tern: datas[1] && datas[1].text,
			department: datas[2] && datas[2].text,
			serial: datas[3] && datas[3].text,
			grade: datas[4] && datas[4].text,
			class_name: datas[5] && datas[5].text,
			name: datas[6] && datas[6].text,
			name_url: datas[6] && datas[6].css('a')[0] && datas[6].css('a')[0][:href],
			credits: datas[7] && datas[7].text,
			semester: datas[8] && datas[8].text,
			required:datas[9] && datas[9].text,
			lecturer:datas[11] && datas[11].text,
			classroom:datas[12] && datas[12].text,
			note: datas[20] && datas[20].text,
			periods: periods

		}

	end
end

File.open('courses.json','w'){|file| file.write(JSON.pretty_generate(courses))}