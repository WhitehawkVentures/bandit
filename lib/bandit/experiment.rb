module Bandit
  class Experiment
    attr_accessor :name, :title, :description, :alternatives

    def self.create(name)
      e = Experiment.new(:name => name)
      yield e
      e.validate!
      e.save
      e
    end

    def self.create_or_attach(name)
      if Bandit.experiments.include?(name.to_s)
        experiment = Experiment.new(JSON.parse(Bandit.storage.get_experiment(name)))
        yield experiment
      else
        experiment = Experiment.create(name) do |e|
          yield e
        end
      end
      experiment
    end

    def save
      @storage.save_experiment(self)
    end

    def initialize(args=nil)
      args.each { |k,v| send "#{k}=", v } unless args.nil?
      @storage = Bandit.storage
    end

    def self.instances
      experiment_names = Bandit.storage.get_experiments
      experiments = []
      if experiment_names.present?
        Bandit.storage.get_experiments.each do |experiment_name|
          experiments << Experiment.new(JSON.parse(Bandit.storage.get_experiment(experiment_name)))
        end
      end
      experiments
    end

    def choose(default=nil)
      if default && alternatives.include?(default)
        alt = default
      else
        alt = Bandit.player.choose_alternative(self)
        @storage.incr_participants(self, alt)
      end
      alt
    end

    def convert!(alt, count=1)
      @storage.incr_conversions(self, alt, count)
    end

    def validate!
      [:title, :alternatives].each { |field|        
        unless send(field)
          raise MissingConfigurationError, "#{field} must be set in experiment #{name}"
        end
      }
    end

    def conversion_count(alt, date_hour=nil)
      @storage.conversion_count(self, alt, date_hour)
    end

    def participant_count(alt, date_hour=nil)
      @storage.participant_count(self, alt, date_hour)
    end

    def total_participant_count(date_hour=nil)
      @storage.total_participant_count(self, date_hour)
    end

    def conversion_rate(alt)
      pcount = participant_count(alt)
      ccount = conversion_count(alt)
      (pcount == 0 or ccount == 0) ? 0 : (ccount.to_f / pcount.to_f * 100.0)
    end

    def alternative_start(alt)
      @storage.alternative_start_time(self, alt)
    end
  end
end
