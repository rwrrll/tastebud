#!/usr/bin/env ruby

require 'bundler'
require 'net/http'
require 'json'
require 'optparse'
Bundler.require

def log(message)
  puts "#{Time.now} -- #{message}"
end

def get_shitlist
  uri  = URI('http://kdot-bot.herokuapp.com/hubot/shitlist')
  json = Net::HTTP.get uri
  JSON.parse(json)
end

def replace_track(track, speaker, replacements, position)
  speaker.remove_from_queue(track[:queue_id])
  speaker.add_spotify_to_queue({ id: replacements.sample }, position)
end

options = {}

OptionParser.new do |opts|
  opts.on("--top-gun") do |v|
    options[:top_gun] = true
  end
  opts.on("--swapsies") do |v|
    options[:swapsies] = true
  end
end.parse!

top_gun = [
  '3Y3xIwWyq5wnNHPp5gPjOW',
  '5fRj17ipiGHroKx9u8LkHk',
  '17jHbSrAeRrVhi1omLXQEo',
  '4SaQmpjro3GYFt3Eyvk2g2',
  '1AAEWUVZpew24mP6nC1IU5',
  '5UAJauBWyIroPQwWWdBuz2',
  '5kZkogOFoQP25LDxi6EYgK',
  '6nuykILnip6FtXvMrHty3L',
  '07HD5lOaZ4D94KGHUJ5UG2',
  '6lKtMV1tpaZtMusLUDBHSb',
  '5rBrs0mDpHlKVL5mQFbjuE',
  '6bSRamvdbeVlza5P5Bfq5P',
  '1vBQ620eF9zfP4L3w5TTyI'
]

swapsies = {
  'I Disappear' => [
    '0zkiQH567SDLqfWNBaU3hv', # Selfie
    '38GIXryQTvtuteKojD6YIv'  # Jamie's Cryin
  ],
  'Story of My Life' => [
    '2XxvG64l8WtfZnotwakB9g'  # SamRick
  ],
  'Magic' => [
    '4ob9Bn36rQ9JaeveIllUhf'  # The Wolf I Feed
  ]
}

def replacements_for(title, swapsies)
  swapsies.each_pair do |k, v|
    return v if k.start_with? title
  end
end

class String
  def is_in?(list)
    list.any? { |item| /^#{item}/i.match(self) }
  end
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

    speaker.queue[:items].each_with_index do |track, index|
      if track[:title].is_in?(shitlist)
        if options[:swapsies] && track[:title].is_in?(swapsies.keys)
          log "Swapping '#{track[:title]}'."
          replacements = replacements_for(track[:title], swapsies)
          replace_track(track, speaker, replacements, index + 1)
        elsif options[:top_gun]
          log "Found '#{track[:title]}', top-gunizing this shit."
          replace_track(track, speaker, top_gun, index + 1)
        else
          log "Found '#{track[:title]}', removing that shit."
          speaker.remove_from_queue(track[:queue_id])
        end
      end
    end

    sleep 1
  end
end

threads.each { |t| t.join }
