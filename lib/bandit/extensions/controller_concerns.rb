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
      cookiename = "bandit_#{exp}".intern
      cookiename_converted = "bandit_#{exp}_#{category}_converted".intern
      alt ||= cookies.signed[cookiename]
      unless alt.nil?
        Bandit.get_experiment(exp) && Bandit.get_experiment(exp).convert!(alt, category, count)
        cookies.delete(cookiename, :domain => "touchofmodern.com") if category == "purchase"
      end
    end

    # creates a _converted cookie, prevents multiple conversions
    def bandit_sticky_convert!(exp, alt, category=nil, count=1)
      cookiename = "bandit_#{exp}".intern
      cookiename_converted = "bandit_#{exp}_#{category}_converted".intern
      alt ||= cookies.signed[cookiename]
      unless alt.nil? or cookies.signed[cookiename_converted]
        cookies.permanent.signed[cookiename_converted] = { :value => "true", :domain => "touchofmodern.com" }
        Bandit.get_experiment(exp) && Bandit.get_experiment(exp).convert!(alt, category, count)
      end
    end
  end
end
