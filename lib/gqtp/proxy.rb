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

require "gqtp/server"

module GQTP
  class Proxy
    attr_accessor :listen_host, :listen_port
    attr_accessor :upstream_host, :upstream_port
    def initialize(options={})
      @options = options.dup
      @listen_host = @options[:listen_host] || @options[:listen_address]
      @listen_host ||= "0.0.0.0"
      @listen_port = @options[:listen_port] || 10043
      @upstream_host = @options[:upstream_host] || @options[:upstream_address]
      @upstream_host ||= "127.0.0.1"
      @upstream_port = @options[:upstream_port] || 10043
      # :connection is just for backward compatibility.
      @backend = @options[:backend] || @options[:connection] || :thread
      @server = Server.new(:host => @listen_host,
                           :port => @listen_port,
                           :backend => @backend)
    end

    def run
      @server.on_connect do |client|
        create_backend
      end
      @server.on_request do |request, client, backend|
        backend.write(request.header.pack, request.body) do
          backend.read(Header.size) do |header|
            response_header = Header.parse(header)
            backend.read(response_header.size) do |body|
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
    def create_backend
      begin
        require "gqtp/backend/#{@backend}"
      rescue LoadError
        raise ArgumentError, "unknown backend: <#{@backend.inspect}>: #{$!}"
      end

      require "gqtp/backend/#{@backend}"
      module_name = @backend.to_s.capitalize
      backend_module = GQTP::Backend::const_get(module_name)
      backend_module::Client.new(:host => @upstream_host,
                                 :port => @upstream_port)
    end
  end
end
