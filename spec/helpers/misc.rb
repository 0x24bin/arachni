def issues
    Arachni::Module::Manager.results
end

def spec_path
    @@root
end

def run_http!
    Arachni::HTTP.instance.run
end

def remove_constants( mod, children_only = false )
    return if !(mod.is_a?( Class ) || mod.is_a?( Module )) ||
        !mod.to_s.start_with?( 'Arachni' )

    parent = Object
    mod.to_s.split( '::' )[0..-2].each {
        |ancestor|
        parent = parent.const_get( ancestor.to_sym )
    }

    mod.constants.each { |m| remove_constants( mod.const_get( m ) ) }

    return if children_only
    parent.send( :remove_const, mod.to_s.split( ':' ).last.to_sym )
end

def random_port
    loop do
        port = 5555 + rand( 9999 )
        begin
            socket = Socket.new( :INET, :STREAM, 0 )
            socket.bind( Addrinfo.tcp( "127.0.0.1", port ) )
            socket.close
            return port
        rescue
        end
    end
end

def kill( pid )
    begin
        10.times { Process.kill( 'KILL', pid ) }
        return false
    rescue Errno::ESRCH
        return true
    end
end

def kill_em!
    while ::EM.reactor_running?
        ::EM.stop
        sleep( 0.1 )
    end
end
