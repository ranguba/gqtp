# -*- coding: utf-8 -*-
#
# Copyright (C) 2012  Kouhei Sutou <kou@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

require "socket"
require "thread"

module GQTP
  module Connection
    class Thread
      attr_accessor :host, :port
      def initialize(options={})
        @options = options
        @host = options[:host] || "127.0.0.1"
        @port = options[:port] || 10041
        @socket = TCPSocket.open(@host, @port)
      end

      def write(*chunks)
        thread = ::Thread.new do
          chunks.each do |chunk|
            until chunk.empty?
              written_bytes = @socket.write(chunk)
              break if chunk.bytesize == written_bytes
              chunk = chunk[written_bytes..-1]
            end
          end
          yield if block_given?
        end
        Request.new(thread)
      end

      def read(size=nil)
        thread = ::Thread.new do
          yield(@socket.read(size)) if block_given?
        end
        Request.new(thread)
      end

      class Request
        def initialize(thread)
          @thread = thread
        end

        def wait
          @thread.join
        end
      end
    end
  end
end
