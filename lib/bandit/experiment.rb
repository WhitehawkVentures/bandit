module Bandit
  class Experiment
    CONVERSION_CATEGORIES = { :pageview => :event_count,
                              :add_to_cart => :event_count,
                              :revenue => :cents,
                              :purchase => :event_count}

    attr_accessor :name, :title, :description, :alternatives, :expiration_date

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

    def choose(default=nil, category=nil)
      if default && alternatives.include?(default)
        alt = default
      else
        alt = Bandit.player.choose_alternative(self, category)
        @storage.incr_participants(self, alt)
      end
      alt
    end

    def convert!(alt, category=nil, count=1)
      @storage.incr_conversions(self, alt, category, count)
    end

    def validate!
      [:title, :alternatives].each { |field|        
        unless send(field)
          raise MissingConfigurationError, "#{field} must be set in experiment #{name}"
        end
      }
    end

    def improvement(alt, category)
      if conversion_rate(alt, category) > 0
        return (conversion_rate(alt, category)-conversion_rate(worst_alternative(category), category))/conversion_rate(alt, category)*100.0
      else
        return 0
      end
    end

    def standard_error(alt, category)
      p = conversion_rate(alt, category)/100.0
      n = participant_count(alt, category)

      if n > 0
        return Math.sqrt((p * [(1-p), 0].max) / n)*100.0
      else
        return 0
      end
    end
    
    def confidence_interval(alt, category)
      standard_error(alt, category) * 1.96
    end

    def poz(z)
      if (z == 0.0)
        x = 0.0
      else
        y = 0.5 * z.abs
        if (y > (6 * 0.5))
          x = 1.0
        elsif (y < 1.0)
          w = y * y
          x = ((((((((0.000124818987 * w
          - 0.001075204047) * w + 0.005198775019) * w
          - 0.019198292004) * w + 0.059054035642) * w
          - 0.151968751364) * w + 0.319152932694) * w
          - 0.531923007300) * w + 0.797884560593) * y * 2.0
        else
          y -= 2.0
          x = (((((((((((((-0.000045255659 * y
          + 0.000152529290) * y - 0.000019538132) * y
          - 0.000676904986) * y + 0.001390604284) * y
          - 0.000794620820) * y - 0.002034254874) * y
          + 0.006549791214) * y - 0.010557625006) * y
          + 0.011630447319) * y - 0.009279453341) * y
          + 0.005353579108) * y - 0.002141268741) * y
          + 0.000535310849) * y + 0.999936657524
        end
      end
      return z > 0.0 ? ((x + 1.0) * 0.5) : ((1.0 - x) * 0.5)
    end

    def significance(alt, category)
      best = best_alternative(category)
      p_1 = conversion_rate(best, category)/100.0
      p_2 = conversion_rate(alt, category)/100.0
      se_1 = standard_error(best, category)/100.0
      se_2 = standard_error(alt, category)/100.0

      z_score = (p_2-p_1)/(Math.sqrt(se_1**2 + se_2**2))
      if (Math.sqrt(se_1**2 + se_2**2)) == 0 || z_score > 6
        return 0
      else
        return poz(z_score.abs)*100
      end
    end

    def conversion_count(alt, category, date_hour=nil)
      @storage.conversion_count(self, alt, category, date_hour)
    end

    def participant_count(alt, date_hour=nil)
      @storage.participant_count(self, alt, date_hour)
    end

    def total_participant_count(date_hour=nil)
      @storage.total_participant_count(self, date_hour)
    end

    def conversion_rate(alt, category)
      pcount = participant_count(alt)
      ccount = conversion_count(alt, category)
      (pcount == 0 or ccount == 0) ? 0 : (ccount.to_f / pcount.to_f * 100.0)
    end

    def conversion_per_participant(alt, category)
      pcount = participant_count(alt)
      ccount = conversion_count(alt, category)
      (pcount == 0 or ccount == 0) ? 0 : (ccount / pcount)
    end

    def conversion_rate_low(alt, category)
      conversion_rate(alt, category) - confidence_interval(alt, category)
    end

    def conversion_rate_high(alt, category)
      conversion_rate(alt, category) + confidence_interval(alt, category)
    end

    def alternative_start(alt)
      @storage.alternative_start_time(self, alt)
    end

    def best_alternative(category)
      @best_alternative ||= begin
        best = nil
        best_rate = nil
        self.alternatives.each { |alt|
          rate = self.conversion_rate(alt, category)
          if best_rate.nil? or rate > best_rate
            best = alt
            best_rate = rate
          end
        }
        best
      end
    end

    def worst_alternative(category)
      @worst_alternative ||= begin
        worst = nil
        worst_rate = nil
        self.alternatives.each { |alt|
          rate = self.conversion_rate(alt, category)
          if worst_rate.nil? or rate < worst_rate
            worst = alt
            worst_rate = rate
          end
        }
        worst
      end
    end
  end
end
