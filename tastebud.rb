#!/usr/bin/env ruby

require 'bundler'
Bundler.require

SHIT = [
  'Warm Leatherette',
  'Sex Dwarf'
]

puts "Connecting to Sonos..."
system  = Sonos::System.new
speaker = system.speakers.first

puts "Watching for shit..."
loop do
  speaker.queue[:items].each do |track|
    if SHIT.any? { |s| s.start_with? track[:title] }
      puts "#{Time.now} -- Found '#{track[:title]}', removing that shit."
      speaker.remove_from_queue(track[:queue_id])
    end
  end

  sleep 1
end
