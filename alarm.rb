#!/usr/bin/env ruby

require 'lifx'
require 'optparse'
require 'whenever'

options = {}

parser = OptionParser.new do |opts|
  opts.banner = 'Usage: alarm.rb [options]'
  
  options[:bulb] = nil
  opts.on('-b BULB', '--bulb BULB', 'The label give to the bulb you wish to use to wake up') do |bulb|
    options[:bulb] = bulb
  end
  
  options[:waketime] = '0700'
  opts.on('-w TIME', '--waketime TIME', 'The local system time which you want to wake in 24 hour time - example: 0700') do |time|
    options[:waketime] = time
  end
  
  #softwake [delay]
  
  options[:color] = 'white'
  opts.on('-C', '--color', ['white', 'green', 'orange', 'red'], 'The color to set the light to upon waking')
  
  #fade [color]
  
  opts.on_tail('-h', '--help', 'Show this help message') do
    puts opts
    exit
  end
end

parser.parse!

class Sunrise_Alarm
  
  def initialize(opts)
    client = LIFX::Client.lan
    @options = opts
    
    #make sure we have a valid time of day
    pattern = /([0-1][0-9]|2[0-3])([0-5][0-9])/
    if !(pattern.match(@options[:waketime])) then
      # error handling
      puts  "#{@options[:waketime]} not a valid time"
      exit
    end
    
    # make sure we have a valid bulb
    if @options[:bulb] == nil then
      #error handling
      puts "Please specify a bulb with the -b option"
      exit
    end
    puts "Searching for Lif.x labeled #{@options[:bulb]}"
    client.discover! do |c|
      c.lights.with_label(@options[:bulb])
    end
    if client.lights.with_label(@options[:bulb]) then
      @lx = client.lights.with_label(@options[:bulb])
    else
      #error handling
      puts "#{@options[:bulb]} not found"
    end
  end
  
  def ttw
    now = Time.now
    duration = 6 #difference between @options[:waketime] and now
    return duration
  end
  
  def sunrise
    #if @delay specified wake light from 0-100 over period specified
    
    # else wake light at @waketime to 100
    @lx.turn_on
    @lx.set_power(1)
  end
end

alarm = Sunrise_Alarm.new(options)