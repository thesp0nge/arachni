=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require Arachni::Options.instance.dir['lib'] + 'anemone/page'
require Arachni::Options.instance.dir['lib'] + 'anemone/cookie_store'


#
# Overides Anemone's HTTP class methods:
#  o refresh_connection( ): added proxy support
#  o get_response( ): upped the retry counter to 7 and generalized exception handling
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
module Anemone

class HTTP

    include Arachni::UI::Output

    # Maximum number of redirects to follow on each get_response
    REDIRECT_LIMIT = 5

    # CookieStore for this HTTP client
    attr_reader :cookie_store

    def initialize(opts = {})
      @connections = {}
      @opts = opts
      @cookie_store = CookieStore.new(@opts[:cookies])
    end

    #
    # Fetch a single Page from the response of an HTTP request to *url*.
    # Just gets the final destination page.
    #
    def fetch_page(url, referer = nil, depth = nil)
      fetch_pages(url, referer, depth).last
    end

    #
    # Create new Pages from the response of an HTTP request to *url*,
    # including redirects
    #
    def fetch_pages(url, referer = nil, depth = nil)
      begin
        url = URI(url) unless url.is_a?(URI)
        pages = []
        get(url, referer) do |response, code, location, redirect_to, response_time|
          pages << Page.new(location, :body => response.body.dup,
                                      :code => code,
                                      :headers => response.headers_hash,
                                      :referer => referer,
                                      :depth => depth,
                                      :redirect_to => redirect_to,
                                      :response_time => response_time)
        end

        return pages
      rescue => e
        if verbose?
          puts e.inspect
          puts e.backtrace
        end
        return [Page.new(url, :error => e)]
      end
    end

    #
    # The maximum number of redirects to follow
    #
    def redirect_limit
      @opts[:redirect_limit] || REDIRECT_LIMIT
    end

    #
    # The user-agent string which will be sent with each request,
    # or nil if no such option is set
    #
    def user_agent
      @opts[:user_agent]
    end

    #
    # Does this HTTP client accept cookies from the server?
    #
    def accept_cookies?
      @opts[:accept_cookies]
    end

    private

    #
    # Retrieve HTTP responses for *url*, including redirects.
    # Yields the response object, response code, and URI location
    # for each response.
    #
    def get(url, referer = nil)
        response = get_response(url, referer)
        yield response, response.code, url, '', response.time
    end

    #
    # Get an HTTPResponse for *url*, sending the appropriate User-Agent string
    #
    def get_response(url, referer = nil)
        opts = {}
        opts['Referer'] = referer.to_s if referer
        opts['cookie'] = @cookie_store.to_s unless @cookie_store.empty? || (!accept_cookies? && @opts[:cookies].nil?)

        # response = Arachni::Module::HTTP.instance.get( url.to_s,
        #     :headers         => opts,
        #     :follow_location => true,
        #     :async           => false,
        #     :remove_id       => true
        # ).response

        response = Typhoeus::Request.get( url.to_s,
            :headers                       => opts,
            :disable_ssl_peer_verification => true,
            :username                      => Arachni::Options.instance.url.user,
            :password                      => Arachni::Options.instance.url.password,
            :method                        => :auto,
            :user_agent                    => Arachni::Options.instance.user_agent,
            :follow_location               => true,
            :proxy                         => "#{Arachni::Options.instance.proxy_addr}:#{Arachni::Options.instance.proxy_port}",
            :proxy_username                => Arachni::Options.instance.proxy_user,
            :proxy_password                => Arachni::Options.instance.proxy_pass,
            :proxy_type                    => Arachni::Options.instance.proxy_type,
        )

        # pp response.headers_hash['Set-Cookie']
        # pp @cookie_store

        @cookie_store.merge!(response.headers_hash['Set-Cookie']) if accept_cookies?
        return response
    end


    def verbose?
      @opts[:verbose]
    end

    #
    # Allowed to connect to the requested url?
    #
    def allowed?(to_url, from_url)
      to_url.host.nil? || (to_url.host == from_url.host)
    end


end
end
