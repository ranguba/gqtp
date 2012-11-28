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

require "gqtp/header"

module GQTP
  class Server
    attr_accessor :host, :port
    def initialize(options={})
      @options = options.dup
      @options[:host] ||= "0.0.0.0"
      @options[:port] ||= 10041
      @on_request = nil
    end

    def run
      @connection = create_connection
      @connection.run do |client|
        read_header_request = client.read(Header.size) do |header|
          request_header = Header.parse(header)
          read_body_request = client.read(request_header.size) do |body|
            request = Request.new(request_header, body)
            on_request(request, client)
          end
        end
      end
    end

    def shutdown
      @connection.shutdown
    end

    def on_request(*arguments, &block)
      if block_given?
        @on_request = block
      else
        request, client = arguments
        @on_request.call(request, client)
      end
    end

    private
    def create_connection
      connection = @options[:connection] || :thread

      begin
        require "gqtp/connection/#{connection}"
      rescue LoadError
        raise "unknown connection: <#{connection.inspect}>"
      end

      module_name = connection.to_s.capitalize
      connection_module = GQTP::Connection::const_get(module_name)
      connection_module::Server.new(@options)
    end

    class Request
      attr_reader :header, :body
      def initialize(header, body)
        @header = header
        @body = body
      end
    end
  end
end
