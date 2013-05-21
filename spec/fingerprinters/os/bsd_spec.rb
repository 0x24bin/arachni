require 'spec_helper'

describe Arachni::Platforms::Fingerprinters::BSD do
    include_examples 'fingerprinter'

    context 'when there is an Server header' do
        it 'identifies it as BSD' do
            page = Arachni::Page.new(
                url:     'http://stuff.com/blah',
                response_headers: { 'Server' => 'Apache/2.2.21 (FreeBSD)' }
            )
            platforms_for( page ).should include :bsd
        end
    end

    context 'when there is a X-Powered-By header' do
        it 'identifies it as BSD' do
            page = Arachni::Page.new(
                url:     'http://stuff.com/blah',
                response_headers: { 'X-Powered-By' => 'Stuf/0.4 (FreeBSD)' }
            )
            platforms_for( page ).should include :bsd
        end
    end

end
