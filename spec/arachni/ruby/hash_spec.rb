require 'spec_helper'

describe Hash do
    let( :with_symbols ) do
        {
            stuff: 'blah',
            more: {
                stuff: {
                    blah: 'stuff'
                }
            }
        }
    end

    let( :with_strings ) do
        {
            'stuff' => 'blah',
            'more'  => {
                'stuff' => {
                    'blah' => 'stuff'
                }
            }
        }
    end

    describe '#stringify_keys' do
        it 'recursively converts keys to strings' do
            with_symbols.stringify_keys.should == with_strings
        end

        context 'when the recursive is set to false' do
            it 'only converts the keys at depth 1' do
                with_symbols.stringify_keys( false ).should == {
                    'stuff' => 'blah',
                    'more'  => {
                        stuff: {
                            blah: 'stuff'
                        }
                    }
                }
            end
        end
    end

    describe '#symbolize_keys' do
        it 'recursively converts keys to symbols' do
            with_strings.symbolize_keys.should ==with_symbols
        end

        context 'when the recursive is set to false' do
            it 'only converts the keys at depth 1' do
                with_strings.symbolize_keys( false ).should == {
                    stuff: 'blah',
                    more:  {
                        'stuff' => {
                            'blah' => 'stuff'
                        }
                    }
                }
            end
        end
    end
end
