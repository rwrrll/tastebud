#!/usr/bin/env ruby

require 'bundler'
require 'net/http'
require 'json'
Bundler.require

def log(message)
  puts "#{Time.now} -- #{message}"
end

def get_shitlist
  uri  = URI('http://kdot-bot.herokuapp.com/hubot/shitlist')
  json = Net::HTTP.get uri
  JSON.parse(json)
end

log "Initialising..."
threads   = []
@shitlist = []
@mutex    = Mutex.new

threads << Thread.new do
  loop do
    new_list = get_shitlist
    old_list = @shitlist

    if new_list != old_list
      @mutex.synchronize { @shitlist = new_list }
      log "Updated shitlist!"
    end

    sleep 5
  end
end

threads << Thread.new do
  log "Connecting to Sonos..."
  system  = Sonos::System.new

  log "Watching for shit..."
  loop do
    shitlist = @mutex.synchronize { @shitlist }
    speaker  = system.find_party_master

    speaker.queue[:items].each do |track|
      if shitlist.any? { |s| track[:title].start_with? s }
        log "Found '#{track[:title]}', removing that shit."
        speaker.remove_from_queue(track[:queue_id])
      end
    end

    sleep 1
  end
end

threads.each { |t| t.join }
