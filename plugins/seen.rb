require 'yaml'

class Seen < PluginBase
  
  Seen::ACTIVITY_REGEXP = /^(.*)$/
  Seen::SEEN_REGEXP = /(seen) ([^\?]+)(?=\?)*/
  
  # if BOT_ENVIRONMENT == 'development'
    on_message Regexp.new("#{ACTIVITY_REGEXP.source}", Regexp::IGNORECASE), :update
    on_message Regexp.new("^#{Bot.instance.config['nickname']},\\s+#{SEEN_REGEXP.source}", Regexp::IGNORECASE), :seen
    on_command 'reload', :reload
  # end
  
  def initialize
    puts "entering initialize()"
    
  end
  
  def update(msg)
    puts "entering update()"
    @seen ||= init()

    # puts msg[:message]
    # puts msg[:person]
    # puts msg[:user_id]

    puts msg[:message] =~ ACTIVITY_REGEXP
    puts $1, $2, $3

    left_room = (msg[:message] == "has left the room " ? true : false)
    
    @seen[msg[:person]] = {:time => Time.now(), :left => left_room}
    puts @seen[msg[:person]]

    File.open(File.join(File.dirname(__FILE__), 'seen.yml'), 'w') do |out|
      YAML.dump(@seen, out)
    end
  end
  
  def seen(msg)
    puts 'entering seen()'
    @seen ||= init()
    puts @seen
    puts msg[:message]
    
    puts msg[:message] =~ Regexp.new("^#{Bot.instance.config['nickname']},\\s+#{SEEN_REGEXP.source}", Regexp::IGNORECASE)
    puts $1, $2
    found = false
    
    if !$2.nil?
      first_name = $2.match("[A-Za-z]+")[0]
      
      @seen.each do |person, seenat|
        if person.downcase.include?(first_name.downcase)
          time_ago = time_ago_in_words(seenat[:time])
          left = seenat[:left] ? "leaving the room " : ""
          speak("#{person} was last seen #{left}#{time_ago} ago")
          found = true
        end
      end
      
      if !found
        speak("Sorry, I haven't seen #{first_name}.")
      end
      
    end
  end
  
  def init
    puts "entering init()"
    YAML::load(File.read(File.join(File.dirname(__FILE__), 'seen.yml')))
  end
  
  def reload(msg)
    @facts = init()
    speak("ok, reloaded #{@facts.size} seen db")
  end
  
  protected
  
  def time_ago_in_words(from_time, include_seconds = false)
    distance_of_time_in_words(from_time, Time.now, include_seconds)
  end
  
  def distance_of_time_in_words(from_time, to_time = 0, include_seconds = false)
    from_time = from_time.to_time if from_time.respond_to?(:to_time)
    to_time = to_time.to_time if to_time.respond_to?(:to_time)
    distance_in_minutes = (((to_time - from_time).abs)/60).round
    distance_in_seconds = ((to_time - from_time).abs).round

    case distance_in_minutes
      when 0..1
        return (distance_in_minutes == 0) ? 'less than a minute' : '1 minute' unless include_seconds
        case distance_in_seconds
          when 0..4   then 'less than 5 seconds'
          when 5..9   then 'less than 10 seconds'
          when 10..19 then 'less than 20 seconds'
          when 20..39 then 'half a minute'
          when 40..59 then 'less than a minute'
          else             '1 minute'
        end

        when 2..44           then "#{distance_in_minutes} minutes"
        when 45..89          then 'about 1 hour'
        when 90..1439        then "about #{(distance_in_minutes.to_f / 60.0).round} hours"
        when 1440..2879      then '1 day'
        when 2880..43199     then "#{(distance_in_minutes / 1440).round} days"
        when 43200..86399    then 'about 1 month'
        when 86400..525599   then "#{(distance_in_minutes / 43200).round} months"
        when 525600..1051199 then 'about 1 year'
        else                      "over #{(distance_in_minutes / 525600).round} years"
    end
  end
  
end