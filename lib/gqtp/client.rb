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

require "gqtp/parser"
require "gqtp/sequential-request"

module GQTP
  class Client
    attr_accessor :address, :port
    def initialize(options={})
      @options = options.dup
      @options[:address] ||= "127.0.0.1"
      @options[:port] ||= 10041
      @connection = create_connection
    end

    def send(body, options={}, &block)
      header = options[:header] || Header.new
      header.size = body.bytesize

      if block_given?
        sequential_request = SequentialRequest.new
        write_request = @connection.write(header.pack, body) do
          sequential_request << read(&block)
        end
        sequential_request << write_request
        sequential_request
      else
        @connection.write(header.pack, body)
      end
    end

    def read(&block)
      sync = !block_given?
      parser = Parser.new
      response_body = nil

      sequential_request = SequentialRequest.new
      read_header_request = @connection.read(Header.size) do |header|
        parser << header
        read_body_request = @connection.read(parser.header.size) do |body|
          response_body = body
          yield(parser.header, response_body) if block_given?
        end
        sequential_request << read_body_request
      end
      sequential_request << read_header_request

      if sync
        sequential_request.wait
        [parser.header, response_body]
      else
        sequential_request
      end
    end

    def close
      sync = !block_given?
      ack_request = nil
      quit_request = send("quit", :header => header_for_close) do
        ack_request = send("ACK", :header => header_for_close) do
          @connection.close
          yield if block_given?
        end
      end
      if sync
        quit_request.wait
        ack_request.wait
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
      connection_module::Client.new(@options)
    end

    def header_for_close
      Header.new(:flags => Header::Flag::HEAD)
    end
  end
end
