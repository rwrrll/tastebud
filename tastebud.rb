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

def replace_track(track, speaker, replacements)
  speaker.remove_from_queue(track[:queue_id])
  speaker.add_spotify_to_queue({:id => replacements.sample})
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

def to_swap(title)
  swapsies.each_pair do |k, v|
    return v if k.start_with? title
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

    speaker.queue[:items].each do |track|
      if shitlist.any? { |s| track[:title].start_with? s }
        swap_to = to_swap(s)
        if options[:swapsies] && !swap_to.nil?
          log "Swapping '#{track[:title]}'."
          replace_track(track, speaker, swap_to)
        elsif options[:top_gun]
          log "Found '#{track[:title]}', top-gunizing this shit."
          replace_track(track, speaker, top_gun)
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
