require 'spec_helper'

describe Arachni::Platforms::Fingerprinters::IIS do
    include_examples 'fingerprinter'

    context 'when there is an Server header' do
        it 'identifies it as IIS' do
            page = Arachni::Page.new(
                url:     'http://stuff.com/blah',
                response_headers: { 'Server' => 'IIS/2.2.21' }
            )
            platforms_for( page ).should include :iis
            platforms_for( page ).should include :windows
        end
    end

    context 'when there is a X-Powered-By header' do
        it 'identifies it as IIS' do
            page = Arachni::Page.new(
                url:     'http://stuff.com/blah',
                response_headers: { 'X-Powered-By' => 'Stuf/0.4 (IIS)' }
            )
            platforms_for( page ).should include :iis
            platforms_for( page ).should include :windows
        end
    end

end
