require 'active_support/concern'

module Bandit
  module ViewConcerns
    extend ActiveSupport::Concern

    # The 1st version of our cookies did not expire and grew too large.
    # Delete any we find.
    def delete_v0_cookies
      cookies.each do |cookie|
        Rails.logger.error("cookie name: #{cookie[0]}")
        if cookie[0].include?("bandit_")
          Rails.logger.error("attempting to delete: #{cookie[0]}")
          cookies[cookie[0]] = { :value => "", :expires => 1.day.ago }
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
