require_relative '../../spec_helper'

describe Arachni::Report::Manager do
    before( :all ) do
        opts = Arachni::Options.instance
        opts.dir['reports'] = spec_path + '/fixtures/reports/manager_spec/'

        @framework = Arachni::Framework.new( Arachni::Options.instance )
        @reports   = @framework.reports
        @reports.load( '*' )
    end

    after( :all ){ @reports.clear }

    describe '#run' do
        context 'without the run_afr opt' do
            it 'should run loaded reports including the AFR one' do
                @reports.run( @framework.auditstore )

                File.exist?( 'afr' ).should be_true
                File.delete( 'afr' )

                @reports.keys.each do |name|
                    File.exist?( name ).should be_true
                    File.delete( name )
                end
            end
        end
        context 'with the run_afr opt set to true' do
            it 'should run loaded reports including the AFR one' do
                @reports.run( @framework.auditstore, true )
                File.exist?( 'afr' ).should be_true
                File.delete( 'afr' )

                @reports.keys.each do |name|
                    File.exist?( name ).should be_true
                    File.delete( name )
                end
            end
        end
        context 'with run_afr opt set to false' do
            it 'should run loaded reports without the AFR one' do
                @reports.run( @framework.auditstore, false )
                File.exist?( 'afr' ).should be_false

                @reports.keys.each do |name|
                    File.exist?( name ).should be_true
                    File.delete( name )
                end
            end
        end
    end

    describe '#run_one' do
        it 'should run a report by name' do
            @reports.run_one( 'foo', @framework.auditstore )

            File.exist?( 'foo' ).should be_true
            File.delete( 'foo' )
        end
    end

end
