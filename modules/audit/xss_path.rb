=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

module Arachni
module Modules

#
# XSS in path audit module.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.7
#
# @see http://cwe.mitre.org/data/definitions/79.html
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
#
class XSSPath < Arachni::Module::Base

    def prepare
        @_tag_name = 'my_tag_' + seed
        @str = '<' + @_tag_name + ' />'
        @__injection_strs = [
            @str,
            '?' + @str,
            '?>"\'>' + @str,
            '?=>"\'>' + @str
        ]

        @@audited ||= Set.new
    end

    def run
        path = get_path( page.url )

        return if @@audited.include?( path )
        @@audited << path

        @__injection_strs.each do |str|
            url  = path + str

            print_status( "Checking for: #{url}" )

            req  = http.get( url )

            req.on_complete { |res| check_and_log( res, str ) }
        end
    end

    def check_and_log( res, str )
        # check for the existence of the tag name before parsing to verify
        # no reason to waste resources...
        return if !res.body.substring?( @_tag_name )

        doc = Nokogiri::HTML( res.body )

        # see if we managed to successfully inject our element
        __log_results( res, str ) if !doc.xpath( "//#{@_tag_name}" ).empty?
    end


    def self.info
        {
            :name           => 'XSSPath',
            :description    => %q{Cross-Site Scripting module for path injection},
            :elements       => [ ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.1.7',
            :references     => {
                'ha.ckers' => 'http://ha.ckers.org/xss.html',
                'Secunia'  => 'http://secunia.com/advisories/9716/'
            },
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Cross-Site Scripting (XSS) in path},
                :description => %q{Client-side code, like JavaScript, can
                    be injected into the web application.},
                :tags        => [ 'xss', 'path', 'injection', 'regexp' ],
                :cwe         => '79',
                :severity    => Issue::Severity::HIGH,
                :cvssv2       => '9.0',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end

    def __log_results( res, id )
        url = res.effective_url

        log_issue(
            :var          => 'n/a',
            :url          => url,
            :injected     => id,
            :id           => id,
            :regexp       => 'n/a',
            :regexp_match => 'n/a',
            :elem         => Issue::Element::PATH,
            :response     => res.body,
            :headers      => {
                :request    => res.request.headers,
                :response   => res.headers,
            }
        )

        # inform the user that we have a match
        print_ok( "Match at #{url}" )
        print_verbose( "Injected string: #{id}" )
    end


end
end
end
