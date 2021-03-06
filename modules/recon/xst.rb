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
# Cross-Site tracing recon module.
#
# But not really...it only checks if the TRACE HTTP method is enabled.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
# @see http://cwe.mitre.org/data/definitions/693.html
# @see http://capec.mitre.org/data/definitions/107.html
# @see http://www.owasp.org/index.php/Cross_Site_Tracing
#
class XST < Arachni::Module::Base

    include Arachni::Module::Utilities

    def initialize( page )
        super( page )

        # we need to run only once
        @@__ran ||= false
    end

    def run( )
        return if @@__ran

        print_status( "Checking..." )

        @http.trace( URI( @page.url ).host ).on_complete {
            |res|
            __log_results( res ) if res.code == 200
        }

    end

    def clean_up
        @@__ran = true
    end

    def self.info
        {
            :name           => 'XST',
            :description    => %q{Sends an HTTP TRACE request and checks if it succeeded.},
            :elements       => [ ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :references     => {
                'CAPEC'     => 'http://capec.mitre.org/data/definitions/107.html',
                'OWASP'     => 'http://www.owasp.org/index.php/Cross_Site_Tracing'
            },
            :targets        => { 'Generic' => 'all' },
            :vulnerability   => {
                :name        => %q{The TRACE HTTP method is enabled.},
                :description => %q{This type of attack can occur when the there
                    is an XSS vulnerability and the server supports HTTP TRACE. },
                :cwe         => '693',
                :severity    => Vulnerability::Severity::MEDIUM,
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end

    def __log_results( res )

        vuln = Vulnerability.new( {
            :var          => 'n/a',
            :url          => res.effective_url,
            :injected     => 'n/a',
            :method       => res.request.method.to_s.upcase,
            :id           => 'n/a',
            :regexp       => 'n/a',
            :regexp_match => 'n/a',
            :elem         => Vulnerability::Element::SERVER,
            :response     => res.body,
            :headers      => {
                :request    => res.request.headers,
                :response   => res.headers,
            }
        }.merge( self.class.info ) )

        # register our results with the system
        register_results( [vuln] )

        # inform the user that we have a match
        print_ok( "TRACE is enabled." )
    end

end
end
end
