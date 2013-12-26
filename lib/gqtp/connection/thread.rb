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
    module Thread
      class Request
        def initialize(thread)
          @thread = thread
        end

        def wait
          @thread.join
        end
      end

      class IO
        def initialize(real_io)
          @real_io = real_io
        end

        def write(*chunks)
          thread = ::Thread.new do
            chunks.each do |chunk|
              until chunk.empty?
                written_bytes = @real_io.write(chunk)
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
            data = @real_io.read(size)
            if block_given?
              yield(data)
            else
              data
            end
          end
          Request.new(thread)
        end

        def close
          @real_io.close
        end
      end

      class Client
        attr_accessor :address, :port
        def initialize(options={})
          @options = options
          @address = options[:address] || "127.0.0.1"
          @port = options[:port] || 10043
          @socket = TCPSocket.open(@address, @port)
          @io = IO.new(@socket)
        end

        def write(*chunks, &block)
          @io.write(*chunks, &block)
        end

        def read(size=nil, &block)
          @io.read(size, &block)
        end

        def close
          @io.close
        end
      end

      class Server
        attr_accessor :address, :port
        def initialize(options={})
          @options = options
          @address = options[:address] || "0.0.0.0"
          @port = options[:port] || 10043
          @backlog = options[:backlog] || 128
        end

        def run
          @server = TCPServer.new(@address, @port)
          @server.listen(@backlog)
          thread = ::Thread.new do
            loop do
              client = @server.accept
              ::Thread.new do
                yield(IO.new(client))
              end
            end
          end
          Request.new(thread)
        end

        def shutdown
          @server.shutdown
        end
      end
    end
  end
end
