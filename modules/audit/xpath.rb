=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Modules

#
# XPath Injection audit module.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
# @see http://cwe.mitre.org/data/definitions/91.html
# @see http://www.owasp.org/index.php/XPATH_Injection
# @see http://www.owasp.org/index.php/Testing_for_XPath_Injection_%28OWASP-DV-010%29
#
class XPathInjection < Arachni::Module::Base

    include Arachni::Module::Utilities

    def initialize( page )
        super( page )
    end

    def prepare( )

        #
        # we make this a class variable and populate it only once
        # to reduce file IO
        #
        @@__regexps ||= []

        if @@__regexps.empty?
            read_file( 'regexps.txt' ) { |regexp| @@__regexps << regexp }
        end

        # prepare the strings that will hopefully cause the webapp
        # to output XPath error messages
        @__injection_strs = [
            "'\"",
            "<!--"
        ]

        @__opts = {
            :format => [ Format::APPEND ],
            :regexp => @@__regexps
        }

    end

    def run( )
        @__injection_strs.each {
            |str|
            audit( str, @__opts )
        }
    end


    def self.info
        {
            :name           => 'XPathInjection',
            :description    => %q{XPath injection module},
            :elements       => [
                Vulnerability::Element::FORM,
                Vulnerability::Element::LINK,
                Vulnerability::Element::COOKIE
            ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :references     => {
                'OWASP'      => 'http://www.owasp.org/index.php/XPATH_Injection'
            },
            :targets        => { 'Generic' => 'all' },
            :vulnerability   => {
                :name        => %q{XPath Injection},
                :description => %q{XPath queries can be injected into the web application.},
                :cwe         => '91',
                :severity    => Vulnerability::Severity::HIGH,
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => ''
            }

        }
    end

end
end
end
