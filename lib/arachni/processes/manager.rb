=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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

require 'singleton'
require 'eventmachine'

module Arachni
module Processes

#
# Helper for managing processes.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Manager
    include Singleton

    # @return   [Array<Integer>] PIDs of all running processes.
    attr_reader :pids

    def initialize
        @pids           = []
        @discard_output = true
    end

    #
    # @param    [Integer]   pid
    #   Adds a PID to the {#list} and detaches the process.
    #
    # @return   [Integer]   `pid`
    #
    def <<( pid )
        @pids << pid
        Process.detach pid
        pid
    end

    # @param    [Integer]   pid PID of the process to kill.
    def kill( pid )
        loop do
            begin
                Process.kill( 'KILL', pid )
            rescue Errno::ESRCH
                @pids.delete pid
                return
            end
        end
    end

    # @param    [Array<Integer>]   pids PIDs of the process to {#kill}.
    def kill_many( pids )
        pids.each { |pid| kill pid }
    end

    # Kills all {#processes}.
    def killall
        kill_many @pids.dup
        @pids.clear
    end

    # Stops the EventMachine reactor.
    def kill_em
        ::EM.stop while ::EM.reactor_running? && sleep( 0.1 )
    rescue
        nil
    end

    # @param    [Block] block   Block to fork and discard its output.
    def quite_fork( &block )
        self << fork( &discard_output( &block ) )
    end

    # @param    [Block] block
    #   Block to fork and run inside EventMachine's reactor thread -- its output
    #   will be discarded..
    def fork_em( *args, &block )
        self << ::EM.fork_reactor( *args, &discard_output( &block ) )
    end

    # Overrides the default setting of discarding process outputs.
    def preserve_output
        @discard_output = false
    end

    # @param    [Block] block   Block to run silently.
    def discard_output( &block )
        if !block_given?
            @discard_output = true
            return
        end

        proc do
            if @discard_output
                $stdout.reopen( '/dev/null', 'w' )
                $stderr.reopen( '/dev/null', 'w' )
            end
            block.call
        end
    end

    def self.method_missing( sym, *args, &block )
        if instance.respond_to?( sym )
            instance.send( sym, *args, &block )
        elsif
        super( sym, *args, &block )
        end
    end

    def self.respond_to?( m )
        super( m ) || instance.respond_to?( m )
    end

end

end
end
