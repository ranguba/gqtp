# -*- coding: utf-8 -*-
#
# Copyright (C) 2012-2013  Kouhei Sutou <kou@clear-code.com>
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

require "gqtp/server"

module GQTP
  class Proxy
    attr_accessor :listen_address, :listen_port
    attr_accessor :upstream_address, :upstream_port
    def initialize(options={})
      @options = options.dup
      @listen_address = @options[:listen_address] || "0.0.0.0"
      @listen_port = @options[:listen_port] || 10043
      @upstream_address = @options[:upstream_address] || "127.0.0.1"
      @upstream_port = @options[:upstream_port] || 10043
      @connection = @options[:connection] || :thread
      @server = Server.new(:address => @listen_address,
                           :port => @listen_port,
                           :connection => @connection)
    end

    def run
      @server.on_connect do |client|
        create_connection
      end
      @server.on_request do |request, client, connection|
        connection.write(request.header.pack, request.body) do
          connection.read(Header.size) do |header|
            response_header = Header.parse(header)
            connection.read(response_header.size) do |body|
              client.write(header, body) do
              end
            end
          end
        end
      end
      @server.run
    end

    def shutdown
      @server.shutdown
    end

    private
    def create_connection
      begin
        require "gqtp/connection/#{@connection}"
      rescue LoadError
        raise "unknown connection: <#{@connection.inspect}>"
      end

      require "gqtp/connection/#{@connection}"
      module_name = @connection.to_s.capitalize
      connection_module = GQTP::Connection::const_get(module_name)
      connection_module::Client.new(:address => @upstream_address,
                                    :port => @upstream_port)
    end
  end
end
