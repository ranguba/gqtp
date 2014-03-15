# -*- coding: utf-8 -*-
#
# Copyright (C) 2014  Kouhei Sutou <kou@clear-code.com>
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

require "eventmachine"

module GQTP
  module Backend
    module Eventmachine
      class Request
        def wait
          # Do nothing
        end
      end

      module Handler
        def post_init
          @read_callbacks = []
          @buffer = "".force_encoding("ASCII-8BIT")
        end

        def write(*chunks, &block)
          chunks.each do |chunk|
            send_data(chunk)
          end
          if block_given?
            block.call
          else
            Request.new
          end
        end

        def read(size, &block)
          if @buffer.bytesize >= size
            consume_data(size, block)
          else
            @read_callbacks << [size, block]
          end
          if block_given?
            nil
          else
            Request.new
          end
        end

        def receive_data(data)
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
          @connection = EventMachine.connect(@host, @port, Handler)
        end

        def write(*chunks, &block)
          @connection.write(*chunks, &block)
        end

        def read(size, &block)
          @connection.read(size, &block)
        end

        def close
          @connection.close_connection_after_writing
        end
      end

      module ServerHandler
        include Handler

        def initialize(client_handler)
          super()
          @client_handler = client_handler
        end

        def post_init
          super
          @client_handler.call(self)
        end
      end

      class Server
        attr_accessor :host, :port
        def initialize(options={})
          @options = options
          @host = options[:host] || "0.0.0.0"
          @port = options[:port] || 10043
        end

        def run(&block)
          @signature =
            EventMachine.start_server(@host, @port, ServerHandler, block)
          Request.new
        end

        def shutdown
          EventMachine.stop_server(@signature)
        end
      end
    end
  end
end
