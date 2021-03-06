=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Modules

#
# XSS in URI audit module.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.3
#
# @see http://cwe.mitre.org/data/definitions/79.html
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
#
class XSSURI < Arachni::Module::Base

    include Arachni::Module::Utilities

    def initialize( page )
        super( page )

        @results    = []

        # since we'll bypass the Auditor we need to keep track of our audits
        @@__audited  ||= []
    end

    def prepare( )
        @str = '/<arachni_xss_uri_' + seed
    end

    def run( )

    uri  = URI( @page.url )
    url  = uri.scheme + '://' + uri.host + uri.path  + @str

    if @@__audited.include?( url )
        print_info( 'Skipping already audited url: ' + url )
        return
    end

    @@__audited << url

    req  = @http.get( url )

    req.on_complete {
        |res|
        __log_results( res )
    }

    end


    def self.info
        {
            :name           => 'XSSURI',
            :description    => %q{Cross-Site Scripting module for path injection},
            :elements       => [ ],
            :author         => 'zapotek',
            :version        => '0.1.3',
            :references     => {
                'ha.ckers' => 'http://ha.ckers.org/xss.html',
                'Secunia'  => 'http://secunia.com/advisories/9716/'
            },
            :targets        => { 'Generic' => 'all' },
            :vulnerability   => {
                :name        => %q{Cross-Site Scripting (XSS) in URI},
                :description => %q{Client-side code, like JavaScript, can
                    be injected into the web application.},
                :cwe         => '79',
                :severity    => Vulnerability::Severity::HIGH,
                :cvssv2       => '9.0',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end

    def __log_results( res )

        regexp = Regexp.new( Regexp.escape( @str ) )

        if ( res.body.scan( regexp )[0] == @str )

            url = res.effective_url
            # append the result to the results hash
            @results << Vulnerability.new( {
                :var          => 'n/a',
                :url          => url,
                :injected     => @str,
                :id           => @str,
                :regexp       => regexp,
                :regexp_match => @str,
                :elem         => Vulnerability::Element::PATH,
                :response     => res.body,
                :headers      => {
                    :request    => res.request.headers,
                    :response   => res.headers,
                }
            }.merge( self.class.info ) )

            # inform the user that we have a match
            print_ok( "In #{@page.url} at " + url )

            # register our results with the system
            register_results( @results )

        end
    end


end
end
end
