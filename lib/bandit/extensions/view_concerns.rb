require 'active_support/concern'

module Bandit
  module ViewConcerns
    extend ActiveSupport::Concern

    # The 1st version of our cookies did not expire and grew too large.
    # Delete any we find.
    def delete_v0_cookies
      cookies.each do |cookie|
        if cookie[0].include?("bandit_")
          cookies[cookie[0]] = ""
          cookies[cookie[0]] = nil
          cookies[cookie[0].intern] = ""
          cookies[cookie[0].intern] = nil
          cookies[cookie[0]] = { :value => nil }
          cookies[cookie[0]] = { :value => "" }
          cookies[cookie[0].intern] = { :value => nil }
          cookies[cookie[0].intern] = { :value => "" }
          cookies[cookie[0].intern] = { :value => nil, :expires => 1.day.ago }
          cookies[cookie[0].intern] = { :value => nil, :expires => 1.day.ago, :domain => "www.touchofmodern.com" }
          cookies[cookie[0].intern] = { :value => nil, :expires => 1.day.ago, :domain => "touchofmodern.com" }
          cookies[cookie[0].intern] = { :value => nil, :expires => 1.day.ago, :domain => ".touchofmodern.com" }
          cookies.signed[cookie[0].intern] = { :value => nil, :expires => 1.day.ago }
          cookies.signed[cookie[0].intern] = { :value => nil, :expires => 1.day.ago, :domain => "www.touchofmodern.com" }
          cookies.signed[cookie[0].intern] = { :value => nil, :expires => 1.day.ago, :domain => "touchofmodern.com" }
          cookies.signed[cookie[0].intern] = { :value => nil, :expires => 1.day.ago, :domain => ".touchofmodern.com" }
          cookies[cookie[0].intern] = { :value => "", :expires => 1.day.ago }
          cookies[cookie[0].intern] = { :value => "", :expires => 1.day.ago, :domain => "www.touchofmodern.com" }
          cookies[cookie[0].intern] = { :value => "", :expires => 1.day.ago, :domain => "touchofmodern.com" }
          cookies[cookie[0].intern] = { :value => "", :expires => 1.day.ago, :domain => ".touchofmodern.com" }
          cookies.signed[cookie[0].intern] = { :value => "", :expires => 1.day.ago }
          cookies.signed[cookie[0].intern] = { :value => "", :expires => 1.day.ago, :domain => "www.touchofmodern.com" }
          cookies.signed[cookie[0].intern] = { :value => "", :expires => 1.day.ago, :domain => "touchofmodern.com" }
          cookies.signed[cookie[0].intern] = { :value => "", :expires => 1.day.ago, :domain => ".touchofmodern.com" }
          cookies.delete(cookie[0], :domain => "www.touchofmodern.com")
          cookies.delete(cookie[0], :domain => ".touchofmodern.com")
          cookies.delete(cookie[0], :domain => "touchofmodern.com")
          cookies.delete(cookie[0], :domain => :all)
          cookies.delete(cookie[0])
        end
      end
    end

    # default choose is a session based choice
    def bandit_choose(exp, category = nil)
      delete_v0_cookies
      bandit_sticky_choose(exp, category)
    end

    # always choose something new and increase the participant count
    def bandit_simple_choose(exp, category = nil)
      Bandit.get_experiment(exp).choose(nil, category, is_robot?)
    end

    # stick to one alternative for the entire browser session
    def bandit_session_choose(exp, category = nil)
      name = "bt_#{exp}".intern
      # choose url param with preference
      value = params[name].nil? ? cookies.signed[name] : params[name]
      # choose with default, and set cookie
      experiment = Bandit.get_experiment(exp)
      alternative = experiment.choose(value, category, is_robot?)
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
                      experiment.choose(value, category, is_robot?)
                    end
      # re-set cookie
      cookies.signed[name] = { :value => alternative, :domain => "touchofmodern.com", :expires => experiment.expiration_date.present? ? Time.parse(experiment.expiration_date) : 7.days.from_now }
      alternative
    end

    def is_robot?
        puts request.user_agent
        puts Bandit::Config.robot_regex
        puts request.user_agent =~ Bandit::Config.robot_regex
        defined?(request) && request.user_agent =~ Bandit::Config.robot_regex
    end
  end
end
