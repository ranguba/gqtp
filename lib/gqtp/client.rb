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

require "gqtp/parser"
require "gqtp/sequential-request"

module GQTP
  class Client
    attr_accessor :host, :port
    def initialize(options={})
      @options = options.dup
      @options[:host] ||= @options[:address] || "127.0.0.1"
      @options[:port] ||= 10043
      @backend = create_backend
      @close_requesting = false
    end

    def send(body, options={}, &block)
      header = options[:header] || Header.new
      header.size = body.bytesize

      case body
      when /\A(?:shutdown|quit)(?:\z|\s)/
        @close_requesting = true
      when /\A\/d\/(?:shutdown|quit)(?:\z|\?)/
        @close_requesting = true
      end

      if block_given?
        sequential_request = SequentialRequest.new
        write_request = @backend.write(header.pack, body) do
          sequential_request << read(&block)
        end
        sequential_request << write_request
        sequential_request
      else
        @backend.write(header.pack, body)
      end
    end

    def read(&block)
      sync = !block_given?
      parser = Parser.new
      response_body = nil

      sequential_request = SequentialRequest.new
      read_header_request = @backend.read(Header.size) do |header|
        parser << header
        read_body_request = @backend.read(parser.header.size) do |body|
          response_body = body
          if @close_requesting
            @backend.close
            @backend = nil
          end
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

    # Closes the opened connection. You can't send a new request after
    # this method is called.
    #
    # @overload close
    #   Closes synchronously.
    #
    #   @return [true]
    #
    # @overload close {}
    #   Closes asynchronously.
    #
    #   @yield [] Calls the block when the opened connection is closed.
    #   @return [#wait] The request object. If you want to wait until
    #      the request is processed. You can send #wait message to the
    #      request.
    def close
      sync = !block_given?
      sequential_request = SequentialRequest.new
      if @backend
        quit_request = send("quit", :header => header_for_close) do
          yield if block_given?
        end
        sequential_request << quit_request
      end

      if sync
        sequential_request.wait
        true
      else
        sequential_request
      end
    end

    private
    def create_backend
      # :connection is just for backward compatibility.
      backend = @options[:backend] || @options[:connection] || :thread

      begin
        require "gqtp/backend/#{backend}"
      rescue LoadError
        raise ArgumentError, "unknown backend: <#{backend.inspect}>: #{$!}"
      end

      module_name = backend.to_s.capitalize
      backend_module = GQTP::Backend.const_get(module_name)
      backend_module::Client.new(@options)
    end

    def header_for_close
      Header.new(:flags => Header::Flag::HEAD)
    end
  end
end
