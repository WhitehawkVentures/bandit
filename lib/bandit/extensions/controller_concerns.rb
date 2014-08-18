require 'active_support/concern'

module Bandit
  module ControllerConcerns
    extend ActiveSupport::Concern

    # default convert is a session based conversion
    def bandit_convert!(exp, alt, category=nil, count=1)
      bandit_session_convert!(exp, alt, category, count)
    end

    # look mum, no cookies
    def bandit_simple_convert!(exp, alt, category=nil, count=1)
      Bandit.get_experiment(exp) && Bandit.get_experiment(exp).convert!(alt, category, count)
    end

    # expects a session cookie, deletes it, will convert again
    def bandit_session_convert!(exp, alt, category=nil, count=1)
      uuid = cookies["bttomo_uuid".intern]
      unless uuid.present?
        uuid = SecureRandom.uuid
        cookies["bttomo_uuid".intern] = { :value => uuid, :domain => Rails.env.development? ? "touchofmodern.local" : "touchofmodern.com" }
      end
      state = Bandit.storage.states_get(uuid, exp)

      alt = state
      experiment = Bandit.get_experiment(exp)
      unless alt.nil?
        Bandit.get_experiment(exp) && Bandit.get_experiment(exp).convert!(alt, category, count, is_robot?)
        if category == :purchase
          Bandit.storage.states_delete(uuid, exp)
        else
          Bandit.storage.states_set(uuid, exp, alt)
        end
      end



      #
      #cookiename = "bt_#{exp}".intern
      #cookiename_converted = "bt_#{exp}_#{category}_converted".intern
      #alt ||= cookies.signed[cookiename]
      #experiment = Bandit.get_experiment(exp)
      #unless alt.nil?
      #  Bandit.get_experiment(exp) && Bandit.get_experiment(exp).convert!(alt, category, count)
      #  cookies.signed[cookiename] = { :value => alt, :domain => "touchofmodern.com", :expires => experiment.expiration_date.present? ? Time.parse(experiment.expiration_date) : 5.days.from_now }
      #  cookies.delete(cookiename, :domain => "touchofmodern.com") if category == :purchase
      #end
    end

    # creates a _converted cookie, prevents multiple conversions
    def bandit_sticky_convert!(exp, alt, category=nil, count=1)
      cookiename = "bt_#{exp}".intern
      cookiename_converted = "bt_#{exp}_#{category}_converted".intern
      alt ||= cookies.signed[cookiename]
      unless alt.nil? or cookies.signed[cookiename_converted]
        experiment = Bandit.get_experiment(exp)
        cookies.signed[cookiename_converted] = { :value => "true", :domain => "touchofmodern.com", :expires => experiment.expiration_date.present? ? Time.parse(experiment.expiration_date) : 5.days.from_now }
        experiment && experiment.convert!(alt, category, count, is_robot?)
      end
    end
    
    def is_robot?
        defined?(request) && request.user_agent =~ Bandit.robot_regex
    end
  end
end
