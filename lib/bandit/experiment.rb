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
      experiment = Bandit.storage.get_experiment(name)
      if experiment
        experiment = Experiment.new(JSON.parse(experiment))
        yield experiment
      else
        experiment = Experiment.create(name) do |e|
          yield e
        end
      end
      experiment  
      
      # if Bandit.experiments.include?(name.to_s)
      #   experiment = Experiment.new(JSON.parse(Bandit.storage.get_experiment(name)))
      #   yield experiment
      # else
      #   experiment = Experiment.create(name) do |e|
      #     yield e
      #   end
      # end
      # experiment
    end
    
    def self.get(name)
      if Bandit.storage.get_experiment(name).present? && Bandit.storage.get_experiment(name) != 0
        experiment = Experiment.new(JSON.parse(Bandit.storage.get_experiment(name)))
      else
        nil
      end
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

    def choose(default=nil, category=nil, exclude=nil)
      if default && alternatives.include?(default)
        alt = default
      else
        alt = Bandit.player.choose_alternative(self, category)
        unless exclude
            @storage.incr_participants(self, alt)
        else
            puts "BOT BLOCKED"
        end
      end
      alt
    end

    def convert!(alt, category=nil, count=1, exclude=nil)
        unless exclude    
            @storage.incr_conversions(self, alt, category, count)
        else
            puts "BOT BLOCKED"
        end
    end

    def validate!
      [:title, :alternatives].each { |field|        
        unless send(field)
          raise MissingConfigurationError, "#{field} must be set in experiment #{name}"
        end
      }
    end

    def improvement(alt, category)
      if conversion_rate(alt, category) > 0 &&
                                      conversion_rate(worst_alternative(category), category) > 0
        return (conversion_rate(alt, category)-conversion_rate(worst_alternative(category), category))/conversion_rate(worst_alternative(category), category)*100.0
      else
        return 0
      end
    end

    def standard_error(alt, category)
      p = conversion_rate(alt, category)/100.0
      n = participant_count(alt)

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
        return (1-poz(z_score.abs))*100
      end
    end

    def conversion_count(alt, category, date_hour=nil)
      if instance_variable_get("@conversion_count_#{alt.to_s}_#{category.to_s}_#{date_hour.to_i}").present?
        return instance_variable_get("@conversion_count_#{alt.to_s}_#{category.to_s}_#{date_hour.to_i}")
      else
        conversion_count = @storage.conversion_count(self, alt, category, date_hour)
        instance_variable_set("@conversion_count_#{alt.to_s}_#{category.to_s}_#{date_hour.to_i}", conversion_count)
        return conversion_count
      end
    end

    def participant_count(alt, date_hour=nil)
      if instance_variable_get("@participant_count_#{alt.to_s}_#{date_hour.to_i}").present?
        return instance_variable_get("@participant_count_#{alt.to_s}_#{date_hour.to_i}")
      else
        participant_count = @storage.participant_count(self, alt, date_hour)
        instance_variable_set("@participant_count_#{alt.to_s}_#{date_hour.to_i}", participant_count)
        return participant_count
      end
    end

    def total_participant_count(date_hour=nil)
      if instance_variable_get("@total_participant_count_#{date_hour.to_i}").present?
        return instance_variable_get("@total_participant_count_#{date_hour.to_i}")
      else
        total_participant_count = @storage.total_participant_count(self, date_hour)
        instance_variable_set("@total_participant_count_#{date_hour.to_i}", total_participant_count)
        return total_participant_count
      end
    end

    def conversion_rate(alt, category)
      if instance_variable_get("@conversion_rate_#{alt.to_s}_#{category.to_s}").present?
        return instance_variable_get("@conversion_rate_#{alt.to_s}_#{category.to_s}")
      else
        pcount = participant_count(alt)
        ccount = conversion_count(alt, category)
        conversion_rate = (pcount == 0 or ccount == 0) ? 0 : (ccount.to_f / pcount.to_f * 100.0)
        instance_variable_set("@conversion_rate_#{alt.to_s}_#{category.to_s}", conversion_rate)
        return conversion_rate
      end
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
      if instance_variable_get("@alternative_start_#{alt.to_s}").present?
        return instance_variable_get("@alternative_start_#{alt.to_s}")
      else
        alternative_start = @storage.alternative_start_time(self, alt)
        instance_variable_set("@alternative_start_#{alt.to_s}", alternative_start)
        return alternative_start
      end
    end

    def best_alternative(category)
      if instance_variable_get("@best_alternative_#{category.to_s}").present?
        return instance_variable_get("@best_alternative_#{category.to_s}")
      else
        best = nil
        best_rate = nil
        self.alternatives.each { |alt|
          rate = self.conversion_rate(alt, category)
          if best_rate.nil? or rate > best_rate
            best = alt
            best_rate = rate
          end
        }
        instance_variable_set("@best_alternative_#{category.to_s}", best)
        return best
      end
    end

    def worst_alternative(category)
      if instance_variable_get("@worst_alternative_#{category.to_s}").present?
        return instance_variable_get("@worst_alternative_#{category.to_s}")
      else
        worst = nil
        worst_rate = nil
        self.alternatives.each { |alt|
          rate = self.conversion_rate(alt, category)
          if worst_rate.nil? or rate < worst_rate
            worst = alt
            worst_rate = rate
          end
        }
        instance_variable_set("@worst_alternative_#{category.to_s}", worst)
        return worst
      end
    end
  end
end
