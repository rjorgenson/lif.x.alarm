#!/usr/bin/env ruby

require 'lifx'
require 'optparse'

options = {}

parser = OptionParser.new do |opts|
  opts.banner = 'Usage: alarm.rb [options]'
  
  options[:bulb] = 'all'
  opts.on('-b BULB', '--bulb BULB', 'The label give to the bulb you wish to change - all by default') do |bulb|
    options[:bulb] = bulb
  end
  
  options[:method] = nil
  opts.on('-m METHOD', '--method METHOD', ['sunrise', 'poweron', 'poweroff', 'setcolor', 'setpower'], 'The method you wish to run') do |method|
    options[:method] = method
  end
  
  options[:softwake] = false
  opts.on('-S', '--softwake', 'Run sunrise sequence with delay, requires --delay option') do
    options[:softwake] = true
  end
  
  options[:delay] = 15
  opts.on('-D', '--delay', 'Delay in minutes for the softwake - default 15 minutes') do |delay|
    options[:delay] = delay
  end
  
  options[:color] = '255,255,255'
  opts.on('-C', '--color', 'The RGB value of the color to set the light to') do |color|
    options[:color] = color
  end
  
  options[:power] = 100
  opts.on('-b', '--power', 'The power level you wish to set the bulb to[0-100] - 100 by default') do |power|
    options[:power] = power
  end
  
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
    
    # make sure we have a valid bulb
    if @options[:bulb] == 'all' then
      client.discover!
      @lx = client.lights
    elsif @options[:bulb] == nil then
      puts "Please specify a bulb with the -b option"
      exit
    else
      puts "Searching for Lif.x labeled #{@options[:bulb]}"
      client.discover! do |c|
        c.lights.with_label(@options[:bulb])
      end
      if client.lights.with_label(@options[:bulb]) then
        @lx = client.lights.with_label(@options[:bulb])
      else
        puts "#{@options[:bulb]} not found"
      end
    end
  end
  
  def sunrise
    if @options[:color] then
      self.setcolor
    end
    if @options[:delay] then
      @lx.set_power(0.0)
      @lx.power_on
      i = (@options[:power] / @option[:delay]).to_f * 100
      t = i / @options[:delay].to_f
      i.to_i.times do |p|
        @lx.set_power( p.to_f/100 )
        sleep(t)
      end
    else #turn on light now
      puts "Turning on light #{@options[:bulb]}"
      @lx.turn_on
      @lx.set_power(@options[:power])
    end
  end
  
  def sunset
    if @options[:color] then
      self.setcolor
    end
    @lx.set_power(0.0)
    @lx.power_on
    i = (@options[:power] / @option[:delay]).to_f
    t = i / @options[:delay].to_f
    i.to_i.times do |p|
      @lx.set_power( 1 - (p.to_f/100) )
      sleep(t)
    end
  end
  
  def setcolor
    @lx.set_color(@options[:color])
  end
  
  def setpower
    @lx.set_power((@options[:power] / 100).to_f)
  end
  
  def poweron
    @lx.power_on
  end
  
  def poweroff
    @lx.power_off
  end
end

bulb = Sunrise_Alarm.new(options)

case options[:method]
when "sunrise"
  bulb.sunrise
when "sunset"
  bulb.sunset
when "poweron"
  bulb.poweron
when "poweroff"
  bulb.poweroff
when "setcolor"
  bulb.setcolor
when "setpower"
  bulb.setpower
else
  puts "Please chose a method to run"
end