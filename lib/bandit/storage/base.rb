# Bandit keys:

# Store total count for this alternative (+ by category for conversions)
# conversions:<experiment>:<alternative>:<category> = count
# e.g. conversions:sale_3519_photo:6:pageview => "9"
# TYPE=[none:none:none:string]
# participants:<experiment>:<alternative> = count
# e.g. participants:sale_3519_photo:6 => "1"
# TYPE=[none:none:string]

# Store first time an alternative is used
# altstarted:<experiment>:<alternative> = timestamp
# e.g. altstarted:sale_3519_photo:6 => "1390348800"
# TYPE=[none:none:string]

# Store total count for this alternative per day and hour
# conversions:<experiment>:<alternative>:<category>:<date>:<hour> = count
# e.g. conversions:sale_3519_photo:6:pageview:Tuesday, 21 January, 2014:16 => "5"
# TYPE=[none:none:none:none:string]
# participants:<experiment>:<alternative>:<date>:<hour> = count
# e.g. participants:sale_3519_photo:6:Tuesday, 21 January, 2014:16 => "1"
# TYPE=[none:none:none:string]

# XXX Not actually implemented AFAICT
# If epsilon_greedy player, every so often store current epsilon
# state:<experiment>:<player>:epsilon = 0.1
# e.g.
# TYPE=[]

# persistently store names of experiments
# experiments:<experiment_name>
# e.g. experiments:sale_3519_photo => {
#              "name":"sale_3519_photo",
#              "alternatives":[5,6],
#              "title":"Stellavie  (3519 Photo Test",
#              "description":"A test of the best sale photo for sale ID 3519" }
# TYPE=[set:string]

module Bandit
  class BaseStorage
    def self.get_storage(name, config)
      config ||= {}

      case name
      when :memory then MemoryStorage.new(config)
      when :memcache then MemCacheStorage.new(config)
      when :dalli then DalliStorage.new(config)
      when :redis then RedisStorage.new(config)
      else raise UnknownStorageEngineError, "#{name} not a known storage method"
      end
    end

    # increment key by count
    def incr(key, count)
      raise NotImplementedError
    end

    # initialize key if not set
    def init(key, value)
      raise NotImplementedError
    end

    # get key if exists, otherwise 0
    def get(key, default=0)
      raise NotImplementedError
    end

    # set key with value, regardless of whether it is set or not
    def set(key, value)
      raise NotImplementedError
    end

    # clear all stored values
    def clear!
      raise NotImplementedError
    end

    def incr_participants(experiment, alternative, count=1, date_hour=nil)
      date_hour ||= DateHour.now

      # initialize first start time for alternative if we haven't inited yet
      init alt_started_key(experiment, alternative), date_hour.to_i

      # increment total count and per hour count
      incr part_key(experiment, alternative), count
      incr part_key(experiment, alternative, date_hour), count
    end

    def incr_conversions(experiment, alternative, category=nil, count=1, date_hour=nil)
      # increment total count and per hour count
      incr conv_key(experiment, alternative, category), count
      incr conv_key(experiment, alternative, category, date_hour || DateHour.now), count
    end

    def total_participant_count(experiment, date_hour=nil)
      experiment.alternatives.inject(0) do |tpc, alternative|
        tpc + participant_count(experiment, alternative, date_hour)
      end
    end

    # if date_hour isn't specified, get total count
    # if date_hour is specified, return count for DateHour
    def participant_count(experiment, alternative, date_hour=nil)
      get part_key(experiment, alternative, date_hour)
    end

    # if date_hour isn't specified, get total count
    # if date_hour is specified, return count for DateHour
    def conversion_count(experiment, alternative, category, date_hour=nil)
      get conv_key(experiment, alternative, category, date_hour)
    end

    def player_state_set(experiment, player, name, value)
      set player_state_key(experiment, player, name), value
    end

    def player_state_get(experiment, player, name)
      get player_state_key(experiment, player, name), nil
    end

    def alternative_start_time(experiment, alternative)
      secs = get alt_started_key(experiment, alternative), nil
      secs.nil? ? nil : Time.at(secs).to_date_hour
    end

    # if date_hour is nil, create key for total
    # otherwise, create key for hourly based
    def part_key(exp, alt, date_hour=nil)
      parts = [ "participants", exp.name, alt ]
      parts += [ date_hour.date, date_hour.hour ] unless date_hour.nil?
      make_key parts
    end

    # key for alternative start
    def alt_started_key(experiment, alternative)
      make_key [ "altstarted", experiment.name, alternative ]
    end

    # if date_hour is nil, create key for total
    # otherwise, create key for hourly based
    def conv_key(exp, alt, category, date_hour=nil)
      parts = [ "conversions", exp.name, alt, category ]
      parts += [ date_hour.date, date_hour.hour ] unless date_hour.nil?
      make_key parts
    end

    def player_state_key(exp, player, varname)
      make_key [ "state", exp.name, player.name, varname ]
    end

    def experiment_key(experiment_name)
      make_key ["experiments", experiment_name]
    end

    def make_key(parts)
      parts.join(":")
    end

    def with_failure_grace(fail_default=0)
      begin
        yield
      rescue Exception => e
        Bandit.storage_failed!
        Rails.logger.error "Storage method #{self.class} failed.  Falling back to memory storage."
        fail_default
      end
    end

    # XXX sadd() and smembers() are only implemented in Redis storage; should
    #     make general for other storage types.
    def get_experiments
      smembers "experiments"
    end

    def get_experiment(experiment_name)
      get experiment_key(experiment_name)
    end

    def save_experiment(experiment)
      sadd "experiments", experiment.name
      hash = {}
      experiment.instance_variables.each do |var|
        unless var.to_s == "@storage"
          hash[var.to_s.delete("@")] = experiment.instance_variable_get(var)
        end
      end
      set experiment_key(experiment.name), hash.to_json
    end
  end
end
