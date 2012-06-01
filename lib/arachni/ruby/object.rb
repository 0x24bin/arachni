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

#
# Overloads the {Object} class providing a deep_clone() method
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Object

    #
    # Deep-clones self using a Marshal dump-load.
    #
    # @return   [Object]    duplicate of self
    #
    def deep_clone
        begin
            Marshal.load( Marshal.dump( self ) )
        rescue Exception
            self
        end
    end

end
