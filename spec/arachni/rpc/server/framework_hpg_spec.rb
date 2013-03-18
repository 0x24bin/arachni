require_relative '../../../spec_helper'

require Arachni::Options.instance.dir['lib'] + 'rpc/client/dispatcher'
require Arachni::Options.instance.dir['lib'] + 'rpc/server/dispatcher'

describe Arachni::RPC::Server::Framework do
    before( :all ) do
        @opts = Arachni::Options.instance
        @opts.dir['modules'] = fixtures_path + '/taint_module/'
        @opts.audit_links = true

        @dispatchers = []

        @opts.pool_size = 1
        @get_instance = proc do |opts|
            opts ||= @opts
            port = random_port
            opts.rpc_port = port
            exec_dispatcher( opts )

            port2 =  random_port
            opts.rpc_port = port2
            opts.neighbour = "#{opts.rpc_address}:#{port}"
            opts.pipe_id = 'blah'
            exec_dispatcher( opts )

            dispatcher = Arachni::RPC::Client::Dispatcher.new( opts,
                "#{opts.rpc_address}:#{port}" )

            inst_info = dispatcher.dispatch
            inst = Arachni::RPC::Client::Instance.new( opts,
                inst_info['url'], inst_info['token']
            )
            inst.opts.grid_mode = 'high_performance'
            inst
        end

        @token = 'secret'
        @get_simple_instance = proc do |opts|
            opts ||= @opts
            port = random_port
            opts.rpc_port = port
            fork_em { Arachni::RPC::Server::Instance.new( opts, @token ) }
            sleep 1
            Arachni::RPC::Client::Instance.new( opts,
                "#{opts.rpc_address}:#{port}", @token
            )
        end

        @instance = @get_instance.call
        @framework = @instance.framework
        @modules = @instance.modules
        @plugins = @instance.plugins

        @instance_clean = @get_instance.call
        @framework_clean = @instance_clean.framework

        @stat_keys = [
            :requests, :responses, :time_out_count,
            :time, :avg, :sitemap_size, :auditmap_size, :progress, :curr_res_time,
            :curr_res_cnt, :curr_avg, :average_res_time, :max_concurrency,
            :current_page, :eta,
        ]

    end

    describe '#errors' do
        context 'when no argument has been provided' do
            it 'returns all logged errors' do
                test = 'Test'
                @framework.error_test test
                @framework.errors.last.should end_with test
            end
        end
        context 'when a start line-range has been provided' do
            it 'returns all logged errors after that line' do
                initial_errors = @framework.errors
                errors = @framework.errors( 10 )

                initial_errors[10..-1].should == errors
            end
        end
    end

    describe '#busy?' do
        context 'when the scan is not running' do
            it 'returns false' do
                @framework_clean.busy?.should be_false
            end
        end
        context 'when the scan is running' do
            it 'returns true' do
                @instance.opts.url = server_url_for( :auditor )
                @modules.load( 'taint' )
                @framework.run.should be_true
                @framework.busy?.should be_true
            end
        end
    end
    describe '#version' do
        it 'returns the system version' do
            @framework_clean.version.should == Arachni::VERSION
        end
    end
    describe '#revision' do
        it 'returns the framework revision' do
            @framework_clean.revision.should == Arachni::Framework::REVISION
        end
    end
    describe '#high_performance?' do
        it 'returns true' do
            @framework_clean.high_performance?.should be_true
        end
    end
    describe '#master?' do
        it 'returns false' do
            @framework_clean.high_performance?.should be_true
        end
    end
    describe '#slave?' do
        it 'returns false' do
            @framework_clean.slave?.should be_false
        end
    end
    describe '#solo?' do
        it 'returns true' do
            @framework_clean.solo?.should be_false
        end
    end
    describe '#set_as_master' do
        it 'sets the instance as the master' do
            instance = @get_simple_instance.call
            instance.framework.master?.should be_false
            instance.framework.set_as_master
            instance.framework.master?.should be_true
        end
    end
    describe '#enslave' do
        it 'enslaves another instance and set itself as its master' do
            master = @get_simple_instance.call
            slave  = @get_simple_instance.call

            master.framework.master?.should be_false
            master.framework.enslave( 'url' => slave.url, 'token' => @token )
            master.framework.master?.should be_true
        end
    end
    describe '#output' do
        it 'returns the instance\'s output messages' do
            output = @framework_clean.output.first
            output.keys.first.is_a?( Symbol ).should be_true
            output.values.first.is_a?( String ).should be_true
        end
    end
    describe '#run' do
        context 'when Options#restrict_to_paths is set' do
            it 'fails with exception' do
                instance = @get_instance.call
                instance.opts.url = server_url_for( :framework_hpg )
                instance.opts.restrict_paths = [instance.opts.url]
                instance.modules.load( 'taint' )

                raised = false
                begin
                    instance.framework.run
                rescue Arachni::RPC::Exceptions::RemoteException
                    raised = true
                end
                raised.should be_true
            end
        end

        it 'performs a scan' do
            instance = @instance_clean
            instance.opts.url = server_url_for( :framework_hpg )
            instance.modules.load( 'taint' )
            instance.framework.run.should be_true
            sleep( 1 ) while instance.framework.busy?
            instance.framework.issues.size.should == 500
        end
    end
    describe '#auditstore' do
        it 'returns an auditstore object' do
            auditstore = @instance_clean.framework.auditstore
            auditstore.is_a?( Arachni::AuditStore ).should be_true
            auditstore.issues.should be_any
            issue = auditstore.issues.first
            issue.is_a?( Arachni::Issue ).should be_true
            issue.variations.should be_any
            issue.variations.first.is_a?( Arachni::Issue ).should be_true
        end
    end
    describe '#stats' do
        it 'returns a hash containing general runtime statistics' do
            stats = @instance_clean.framework.stats
            stats.keys.should == @stat_keys
            @stat_keys.each { |k| stats[k].should be_true }
        end
    end
    describe '#paused?' do
        context 'when not paused' do
            it 'returns false' do
                instance = @instance_clean
                instance.framework.paused?.should be_false
            end
        end
        context 'when paused' do
            it 'returns true' do
                instance = @instance_clean
                instance.framework.pause
                instance.framework.paused?.should be_true
            end
        end
    end
    describe '#resume' do
        it 'resumes the scan' do
            instance = @instance_clean
            instance.framework.pause
            instance.framework.paused?.should be_true
            instance.framework.resume.should be_true
            instance.framework.paused?.should be_false
        end
    end
    describe '#clean_up' do
        it 'sets the framework state to finished, wait for plugins to finish and merge their results' do
            instance = @get_instance.call
            instance.opts.url = server_url_for( :framework_hpg )
            instance.modules.load( 'taint' )
            instance.plugins.load( { 'wait' => {}, 'distributable' => {} } )
            instance.framework.run.should be_true
            instance.framework.auditstore.plugins.should be_empty
            instance.framework.busy?.should be_true

            sleep 1 while instance.framework.busy?

            instance_count = instance.framework.progress['instances'].size

            instance.framework.clean_up

            auditstore = instance.framework.auditstore

            auditstore.issues.size.should == 500

            results = auditstore.plugins
            results.should be_any
            results['wait'].should be_any
            results['wait'][:results].should == { stuff: true }
            results['distributable'][:results].should == { stuff: instance_count }
        end
    end
    describe '#progress' do
        before { @progress_keys = %W(stats status busy issues instances messages).sort }

        it 'aliased to #progress_data' do
            instance = @instance_clean
            data = instance.framework.progress_data
            data.keys.sort.should == @progress_keys
        end

        context 'when called without options' do
            it 'returns all progress data' do
                instance = @instance_clean

                data = instance.framework.progress
                data.keys.sort.should == @progress_keys

                keys = (@stat_keys | %w(url status)).flatten.map { |k| k.to_s }.sort

                data['stats'].should be_any
                data['stats'].keys.sort.should == (keys | %w(current_pages)).flatten.sort
                data['instances'].should be_any
                data['status'].should be_true
                data['busy'].nil?.should be_false
                data['messages'].is_a?( Array ).should be_true
                data['issues'].should be_any
                data['instances'].size.should == 2
                data.should_not include 'errors'

                keys = (keys | %w(current_page)).flatten.sort
                data['instances'].first.keys.sort.should == keys
                data['instances'].last.keys.sort.should == keys
            end
        end

        context 'when called with option' do
            describe :errors do
                context 'when set to true' do
                    it 'includes all error messages' do
                        @instance_clean.framework.
                            progress( errors: true )['errors'].should be_empty

                        test = 'Test'
                        @instance_clean.framework.error_test test

                        @instance_clean.framework.
                            progress( errors: true )['errors'].last.
                            should end_with test
                    end
                end
                context 'when set to an Integer' do
                    it 'returns all logged errors after that line per Instance' do
                        initial_errors = @instance_clean.framework.
                            progress( errors: true )['errors']

                        errors = @instance_clean.framework.
                            progress( errors: 10 )['errors']

                        # errors are per instance
                        initial_errors.size.should == errors.size + 9
                    end
                end
            end
            describe :stats do
                context 'when set to false' do
                    it 'excludes statistics' do
                        keys = @instance_clean.framework.progress( stats: false ).
                            keys.sort
                        pk = @progress_keys.dup
                        pk.delete( "stats" )
                        keys.should == pk
                    end
                end
            end
            describe :messages do
                context 'when set to false' do
                    it 'excludes messages' do
                        keys = @instance_clean.framework.progress( messages: false ).
                            keys.sort
                        pk = @progress_keys.dup
                        pk.delete( "messages" )
                        keys.should == pk
                    end
                end
            end
            describe :issues do
                context 'when set to false' do
                    it 'excludes issues' do
                        keys = @instance_clean.framework.progress( issues: false ).
                            keys.sort
                        pk = @progress_keys.dup
                        pk.delete( "issues" )
                        keys.should == pk
                    end
                end
            end
            describe :slaves do
                context 'when set to false' do
                    it 'excludes slave data' do
                        keys = @instance_clean.framework.progress( slaves: false ).
                            keys.sort
                        pk = @progress_keys.dup
                        pk.delete( "instances" )
                        keys.should == pk
                    end
                end
            end
            describe :as_hash do
                context 'when set to true' do
                    it 'includes issues as a hash' do
                        @instance_clean.framework
                            .progress( as_hash: true )['issues']
                        .first.is_a?( Hash ).should be_true
                    end
                end
            end
        end
    end
    describe '#report' do
        it 'returns a hash report of the scan' do
            report = @instance_clean.framework.report
            report.is_a?( Hash ).should be_true
            report['issues'].should be_any

            issue = report['issues'].first
            issue.is_a?( Hash ).should be_true
            issue['variations'].should be_any
            issue['variations'].first.is_a?( Hash ).should be_true
        end

        it 'aliased to #audit_store_as_hash' do
            @instance_clean.framework.report.should ==
                @instance_clean.framework.audit_store_as_hash
        end
        it 'aliased to #auditstore_as_hash' do
            @instance_clean.framework.report.should ==
                @instance_clean.framework.auditstore_as_hash
        end
    end
    describe '#serialized_auditstore' do
        it 'returns a YAML serialized AuditStore' do
            yaml_str = @instance_clean.framework.serialized_auditstore
            YAML.load( yaml_str ).is_a?( Arachni::AuditStore ).should be_true
        end
    end
    describe '#serialized_report' do
        it 'returns a YAML serialized report hash' do
            @instance_clean.framework.serialized_report.should ==
                @instance_clean.framework.report.to_yaml
        end
    end
    describe '#issues' do
        it 'returns an array of issues without variations' do
            issues = @instance_clean.framework.issues
            issues.should be_any

            issue = issues.first
            issue.is_a?( Arachni::Issue ).should be_true
            issue.variations.should be_empty
        end
    end
    describe '#issues_as_hash' do
        it 'returns an array of issues (as hash) without variations' do
            issues = @instance_clean.framework.issues_as_hash
            issues.should be_any

            issue = issues.first
            issue.is_a?( Hash ).should be_true
            issue['variations'].should be_empty
        end
    end

    describe '#restrict_to_elements' do
        it 'returns false' do
            @instance_clean.framework.restrict_to_elements( [] ).should be_false
        end
    end
    describe '#update_page_queue' do
        it 'returns false' do
            @instance_clean.framework.update_page_queue( [] ).should be_false
        end
    end
    describe '#register_issues' do
        it 'returns false' do
            @instance_clean.framework.register_issues( [] ).should be_false
        end
    end
end
