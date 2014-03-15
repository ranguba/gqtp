# -*- coding: utf-8 -*-
#
# Copyright (C) 2012-2014  Kouhei Sutou <kou@clear-code.com>
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

require "cool.io"

module GQTP
  module Backend
    module Coolio
      class Request
        def initialize(loop)
          @loop = loop
        end

        def wait
          @loop.run
        end
      end

      class Socket < ::Coolio::TCPSocket
        def initialize(*args)
          super
          @write_callbacks = []
          @read_callbacks = []
          @request = nil
          @buffer = "".force_encoding("ASCII-8BIT")
        end

        def write(*chunks, &block)
          chunks.each do |chunk|
            super(chunk)
          end
          @write_callbacks << block if block_given?
          Request.new(evloop)
        end

        def on_write_complete
          write_callbacks, @write_callbacks = @write_callbacks, []
          write_callbacks.each do |callback|
            callback.call
          end
        end

        def read(size, &block)
          if @buffer.bytesize >= size
            consume_data(size, block)
          else
            @read_callbacks << [size, block]
          end
          Request.new(evloop)
        end

        def on_read(data)
          @buffer << data
          until @read_callbacks.empty?
            size, callback = @read_callbacks.first
            break if @buffer.bytesize < size
            @read_callbacks.shift
            consume_data(size, callback)
          end
        end

        private
        def consume_data(size, callback)
          data = @buffer[0, size]
          @buffer = @buffer[size..-1]
          callback.call(data)
        end
      end

      class Client
        attr_accessor :host, :port
        def initialize(options={})
          @options = options
          @host = options[:host] || "127.0.0.1"
          @port = options[:port] || 10043
          @loop = options[:loop] || ::Coolio::Loop.default
          @socket = Socket.connect(@host, @port)
          @socket.attach(@loop)
        end

        def write(*chunks, &block)
          @socket.write(*chunks, &block)
        end

        def read(size, &block)
          @socket.read(size, &block)
        end

        def close
          @socket.close
        end
      end

      class Server
        attr_accessor :host, :port
        def initialize(options={})
          @options = options
          @host = options[:host] || "0.0.0.0"
          @port = options[:port] || 10043
          @loop = options[:loop] || ::Coolio::Loop.default
        end

        def run
          @server = ::Coolio::TCPServer.new(@host, @port, Socket) do |client|
            yield(client)
          end
          @server.attach(@loop)
          @loop.run
          Request.new(@loop)
        end

        def shutdown
          @server.close
        end
      end
    end
  end
end
