module Bandit

  class Config
    def self.required_fields
      [:storage, :player]
    end
    
    # storage should be name of storage engine
    attr_accessor :storage

    # storage_config should be hash of storage config values
    attr_accessor :storage_config

    # player should be name of player
    attr_accessor :player

    # player_config should be hash of player config values
    attr_accessor :player_config

    attr_accessor :bots
    attr_accessor :robot_regex

    def check!
      self.class.required_fields.each do |required_field|
        unless send(required_field)
          raise MissingConfigurationError, "#{required_field} must be set"
        end
      end

      @storage_config ||= {}
      @player_config ||= {}
    end

    def bots
      @bots ||= {
        # Indexers
        'AdsBot-Google' => 'Google Adwords',
        'Baidu' => 'Chinese search engine',
        'Baiduspider' => 'Chinese search engine',
        'bingbot' => 'Microsoft bing bot',
        'Butterfly' => 'Topsy Labs',
        'Gigabot' => 'Gigabot spider',
        'Googlebot' => 'Google spider',
        'MJ12bot' => 'Majestic-12 spider',
        'msnbot' => 'Microsoft bot',
        'rogerbot' => 'SeoMoz spider',
        'PaperLiBot' => 'PaperLi is another content curation service',
        'Slurp' => 'Yahoo spider',
        'Sogou' => 'Chinese search engine',
        'spider' => 'generic web spider',
        'UnwindFetchor' => 'Gnip crawler',
        'WordPress' => 'WordPress spider',
        'YandexBot' => 'Yandex spider',
        'ZIBB' => 'ZIBB spider',

        # HTTP libraries
        'Apache-HttpClient' => 'Java http library',
        'AppEngine-Google' => 'Google App Engine',
        'curl' => 'curl unix CLI http client',
        'ColdFusion' => 'ColdFusion http library',
        'EventMachine HttpClient' => 'Ruby http library',
        'Go http package' => 'Go http library',
        'Java' => 'Generic Java http library',
        'libwww-perl' => 'Perl client-server library loved by script kids',
        'lwp-trivial' => 'Another Perl library loved by script kids',
        'Python-urllib' => 'Python http library',
        'PycURL' => 'Python http library',
        'Test Certificate Info' => 'C http library?',
        'Wget' => 'wget unix CLI http client',

        # URL expanders / previewers
        'awe.sm' => 'Awe.sm URL expander',
        'bitlybot' => 'bit.ly bot',
        'bot@linkfluence.net' => 'Linkfluence bot',
        'facebookexternalhit' => 'facebook bot',
        'Feedfetcher-Google' => 'Google Feedfetcher',
        'https://developers.google.com/+/web/snippet' => 'Google+ Snippet Fetcher',
        'LongURL' => 'URL expander service',
        'NING' => 'NING - Yet Another Twitter Swarmer',
        'redditbot' => 'Reddit Bot',
        'ShortLinkTranslate' => 'Link shortener',
        'TweetmemeBot' => 'TweetMeMe Crawler',
        'Twitterbot' => 'Twitter URL expander',
        'UnwindFetch' => 'Gnip URL expander',
        'vkShare' => 'VKontake Sharer',

        # Uptime monitoring
        'check_http' => 'Nagios monitor',
        'NewRelicPinger' => 'NewRelic monitor',
        'Panopta' => 'Monitoring service',
        'Pingdom' => 'Pingdom monitoring',
        'SiteUptime' => 'Site monitoring services',

        # ???
        'DigitalPersona Fingerprint Software' => 'HP Fingerprint scanner',
        'ShowyouBot' => 'Showyou iOS app spider',
        'ZyBorg' => 'Zyborg? Hmmm....',
        'ELB-HealthChecker' => 'ELB Health Check'
      }
    end

    def robot_regex
      @robot_regex ||= /\b(?:#{escaped_bots.join('|')})\b|\A\W*\z/i
    end

    private
    def escaped_bots
      bots.map { |key, _| Regexp.escape(key) }
    end

  end

end
