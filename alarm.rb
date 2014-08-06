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
  opts.on('-m METHOD', '--method METHOD', ['sunrise', 'sunset', 'poweron', 'poweroff', 'setcolor', 'setpower'], 'The method you wish to run') do |method|
    options[:method] = method
  end
  
  options[:delay] = nil
  opts.on('-D DELAY', '--delay DELAY', 'Delay in minutes for the for sunrise or sunset') do |delay|
    options[:delay] = delay.to_i
  end
  
  options[:color] = nil
  opts.on('-C COLOR', '--color COLOR', 'The RGB value of the color to set the light to') do |color|
    options[:color] = color
  end
  
  options[:power] = 100
  opts.on('-p POWER', '--power POWER', 'The power level you wish to set the bulb to[0-100] - 100 by default') do |power|
    options[:power] = power.to_i
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
      sleep(5)
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
    if @options[:color] then
      @options[:color] = LIFX::Color.rgb(@options[:color].split(",")[0].to_i, @options[:color].split(",")[1].to_i, @options[:color].split(",")[2].to_i)
    else
      if @options[:bulb] == 'all'
        @lx.first do |light|
          @options[:color] = light.color
        end
      else
        @options[:color] = @lx.color
      end
    end
  end
  
  def sunrise
    if @options[:color] then
      self.setcolor
    end
    if @options[:delay] then
      self.setpower('off')
      @lx.turn_on
      t = (@options[:delay] * 60) / 100
      @options[:power].to_i.times do |p|
        if @options[:bulb] == 'all' then
          @lx.each do |light|
            light.set_color(light.color.with_brightness(p.to_f/100))
          end
        else
          @lx.set_color(@lx.color.with_brightness(p.to_f/100))
        end
        puts p.to_f/100
        puts t
        sleep(t)
      end
    else #turn on light now
      self.setpower(100)
    end
  end
  
  def sunset
    if @options[:color] then
      self.setcolor
    end
    if @options[:delay] then
      self.setpower(@options[:power])
      @lx.turn_on
      t = (@options[:delay] * 60) / 100
      @options[:power].to_i.times do |p|
        if @options[:bulb] == 'all' then
          @lx.each do |light|
            light.set_color(@options[:color].with_brightness(1 - (p.to_f/100)))
          end
        else
          @lx.set_color(@options[:color].with_brightness(1 - (p.to_f/100)))
        end
        puts 1 - (p.to_f/100)
        puts t
        sleep(t)
      end
    else #turn on light now
      self.setpower('off')
    end
    
    @lx.set_power(0.0)
    @lx.power_on
    i = (@options[:power] / @option[:delay]).to_f
    t = i / @options[:delay].to_f
    i.to_i.times do |p|
      @lx.set_power!( 1 - (p.to_f/100) )
      sleep(t)
    end
  end
  
  def setcolor
    @lx.set_color(@options[:color])
  end
  
  def setpower(level)
    if @options[:bulb] == 'all' then
      @lx.each do |light|
        if level == 'off'
          light.set_color(light.color.with_brightness(0.0))
        else
          light.set_color(light.color.with_brightness((100 / level).to_f))
        end
      end
    else
      if level == 'off'
        @lx.set_color(@lx.color.with_brightness(0.0))
      else
        @lx.set_color(@lx.color.with_brightness((100 / level).to_f))
      end
    end
  end
  
  def poweron
    @lx.turn_on
  end
  
  def poweroff
    @lx.turn_off
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