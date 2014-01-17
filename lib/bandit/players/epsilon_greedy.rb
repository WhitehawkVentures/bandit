module Bandit
  class EpsilonGreedyPlayer < BasePlayer
    include Memoizable

    def choose_alternative(experiment, category)
      epsilon = @config['epsilon'].to_f || 0.1

      # choose best with probability of 1-epsilon
      if rand <= (1-epsilon)
        best_alternative(experiment, category)
      else
        experiment.alternatives.sample
      end
    end

    def best_alternative(experiment, category)
      memoize(experiment.name) { 
        best = nil
        best_rate = nil
        experiment.alternatives.each { |alt|
          rate = experiment.conversion_rate(alt, category)
          if best_rate.nil? or rate > best_rate
            best = alt
            best_rate = rate
          end
        }
        best
      }
    end
    
  end
end
