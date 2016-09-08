#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require 'colorize'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  noko.xpath('//span[@id="Deputies_by_single-member_district_.28relative_majority.29"]/../following-sibling::table').first.css('tr').each do |tr|
    tr.css('td').each_slice(4) do |tds|
      next if tds[2].css('a').text.empty?
      data = {
        name:          tds[2].css('a').first.text.tidy,
        wikipedia__en: tds[2].css('a/@title').first.text.tidy,
        state:         tds[0].text.tidy,
        district:      tds[1].text.tidy,
        party:         tds[3].css('img/@alt').text.tidy,
        term:          '63',
        holder:        1,
        source:        url,
      }
      data[:wikipedia__en] = data[:wikipedia__en].split(" (page does not exist)").first
      data[:party]         = data[:party].split(".svg").first.split("(Mexico)").first.split(" logo").first
      data[:party]         = "Independent" if data[:party] == "Logo Ind.jpg"
      data[:holder]        = 2 if tds[2].text.include? "Replaces"
      puts data[:name] if data[:name] ==
      ScraperWiki.save_sqlite([:name, :wikipedia__en, :state], data)
    end
  end
end

scrape_list('https://en.wikipedia.org/wiki/LXIII_Legislature_of_the_Mexican_Congress')
