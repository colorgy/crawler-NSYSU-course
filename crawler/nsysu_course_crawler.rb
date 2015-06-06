require 'crawler_rocks'
require 'json'
require 'pry'

class NsysuCourseCrawler
  include CrawlerRocks::DSL

  DAYS = %w(一 二 三 四 五 六 日)
  PERIODS = {
    "A" => 1,
    "1" => 2,
    "2" => 3,
    "3" => 4,
    "4" => 5,
    "B" => 6,
    "5" => 7,
    "6" => 8,
    "7" => 9,
    "8" => 10,
    "9" => 11,
    "C" => 12,
    "D" => 13,
    "E" => 14,
    "F" => 15
  }

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil

    @year = params && params["year"].to_i || year
    @term = params && params["term"].to_i || term
    @update_progress_proc = update_progress
    @after_each_proc = after_each
  end

  def courses
    @courses = []

    visit "https://selcrs.nsysu.edu.tw/menu1/dplycourse.asp?#{{
      "a" => '1',
      "D0" => "#{@year-1911}#{@term}",
      "D1" => nil,
      "D2" => nil,
      "CLASS_COD" => nil,
      "T3" => nil,
      "teacher" => nil,
      "crsname" => nil,
      "WKDAY" => '3',
      "SECT" => nil,
      "SECT_COD" => nil,
      "ALL" => nil,
      "CB1" => nil,
      "SPEC" => nil,
      "HIS" => '2',
      "IDNO" => nil,
      "ITEM" => nil,
      "TYP" => '1',
      "bottom_per_page" => 10,
      "data_per_page" => 20,
      "page" => 1}.map{|k, v| "#{k}=#{v}"}.join('&')}"

    @doc.text.match(/第\ \d+\ \/\ (?<pn>\d+)\ 頁/) do |m|
      @page_num = m[:pn].to_i
    end

    (1..@page_num).each do |page_num|
      r = RestClient.get "https://selcrs.nsysu.edu.tw/menu1/dplycourse.asp?#{{
        "a" => '1',
        "D0" => "#{@year-1911}#{@term}",
        "D1" => nil,
        "D2" => nil,
        "CLASS_COD" => nil,
        "T3" => nil,
        "teacher" => nil,
        "crsname" => nil,
        "WKDAY" => '3',
        "SECT" => nil,
        "SECT_COD" => nil,
        "ALL" => nil,
        "CB1" => nil,
        "SPEC" => nil,
        "HIS" => '2',
        "IDNO" => nil,
        "ITEM" => nil,
        "TYP" => '1',
        "bottom_per_page" => 10,
        "data_per_page" => 20,
        "page" => 1}.map{|k, v| "#{k}=#{v}"}.join('&')}"

      document = Nokogiri::HTML(r.to_s)
      document.css('html table tr:nth-child(n+4)')[1..-3].each do |row|
        datas = row.css("td")

        code = "#{@year}-#{@term}-#{datas[3] && datas[3].text}"

        course_days = []
        course_periods = []
        course_locations = []
        location = datas[12] && datas[12].text

        times = datas[13..19]
        times_arr = (0..6).select {|i| !times[i].text.strip.gsub("&nbsp", '').empty?}.map{|i| [(i+1).to_s, times[i].text.strip.gsub("&nbsp", '')]}
        times_h = Hash[times_arr]
        times_h.keys.each do |k|
          times_h[k].split('').each do |p|
            course_days << k
            course_periods << p
            course_locations << location
          end
        end


        @courses << {
          year: @year,
          term: @term,
          department: datas[2] && datas[2].text,
          # serial: datas[3] && datas[3].text,
          code: code,
          grade: datas[4] && datas[4].text,
          # class_name: datas[5] && datas[5].text,
          name: datas[6] && datas[6].text,
          name_url: datas[6] && datas[6].css('a')[0] && datas[6].css('a')[0][:href],
          credits: datas[7] && datas[7].text,
          # semester: datas[8] && datas[8].text,
          required:datas[9] && datas[9].text.include?('必'),
          lecturer:datas[11] && datas[11].text,
          # note: datas[20] && datas[20].text,
          day_1: course_days[0],
          day_2: course_days[1],
          day_3: course_days[2],
          day_4: course_days[3],
          day_5: course_days[4],
          day_6: course_days[5],
          day_7: course_days[6],
          day_8: course_days[7],
          day_9: course_days[8],
          period_1: course_periods[0],
          period_2: course_periods[1],
          period_3: course_periods[2],
          period_4: course_periods[3],
          period_5: course_periods[4],
          period_6: course_periods[5],
          period_7: course_periods[6],
          period_8: course_periods[7],
          period_9: course_periods[8],
          location_1: course_locations[0],
          location_2: course_locations[1],
          location_3: course_locations[2],
          location_4: course_locations[3],
          location_5: course_locations[4],
          location_6: course_locations[5],
          location_7: course_locations[6],
          location_8: course_locations[7],
          location_9: course_locations[8],
        }
      end # end each row
    end # each page
    File.write('courses.json', JSON.pretty_generate(@courses))
    @courses
  end # end courses

  def current_year
    (Time.now.month.between?(1, 7) ? Time.now.year - 1 : Time.now.year)
  end

  def current_term
    (Time.now.month.between?(2, 7) ? 2 : 1)
  end
end


cc = NsysuCourseCrawler.new(year: 2014, term: 1)
cc.courses
