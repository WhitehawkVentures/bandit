module Bandit
  class RoundRobinPlayer < BasePlayer
    def choose_alternative(experiment, category=nil)
      experiment.alternatives.sample
    end
  end
end
