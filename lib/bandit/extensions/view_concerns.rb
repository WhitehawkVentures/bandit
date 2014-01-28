require 'active_support/concern'

module Bandit
  module ViewConcerns
    extend ActiveSupport::Concern

    # default choose is a session based choice
    def bandit_choose(exp, category = nil)
      cookies.each_pair do |key, value|
        if key.include?("bandit_")
          cookies.delete(key, :domain => "touchofmodern.com")
          cookies.delete(key, :domain => "www.touchofmodern.com")
        end
      end
      bandit_sticky_choose(exp, category)
    end

    # always choose something new and increase the participant count
    def bandit_simple_choose(exp, category = nil)
      Bandit.get_experiment(exp).choose(nil, category)
    end

    # stick to one alternative for the entire browser session
    def bandit_session_choose(exp, category = nil)
      name = "bt_#{exp}".intern
      # choose url param with preference
      value = params[name].nil? ? cookies.signed[name] : params[name]
      # choose with default, and set cookie
      experiment = Bandit.get_experiment(exp)
      alternative = experiment.choose(value, category)
      cookies.signed[name] = { :value => alternative, :domain => "touchofmodern.com", :expires => experiment.expiration_date.present? ? Time.parse(experiment.expiration_date) : 7.days.from_now }
      alternative
    end

    # stick to one alternative until user deletes cookies or changes browser
    def bandit_sticky_choose(exp, category = nil)
      name = "bt_#{exp}".intern
      # choose url param with preference
      value = params[name].nil? ? cookies.signed[name] : params[name]
      # sticky choice may outlast a given alternative
      experiment = Bandit.get_experiment(exp)
      alternative = if experiment.alternatives.include?(value)
                      value
                    else
                      experiment.choose(value, category)
                    end
      # re-set cookie
      cookies.signed[name] = { :value => alternative, :domain => "touchofmodern.com", :expires => experiment.expiration_date.present? ? Time.parse(experiment.expiration_date) : 7.days.from_now }
      alternative
    end
  end
end
