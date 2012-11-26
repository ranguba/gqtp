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

require "gqtp/error"
require "gqtp/header"

module GQTP
  class ParseError < Error
  end

  class Parser
    class << self
      def parse(data, &block)
        if block_given?
          event_parse(data, &block)
        else
          stand_alone_parse(data)
        end
      end

      private
      def event_parse(data)
        parser = new

        parser.on_header do |header|
          yield(:on_header, header)
        end
        parser.on_body do |chunk|
          yield(:on_body, chunk)
        end
        parser.on_complete do
          yield(:on_complete)
        end

        consume_data(parser, data)
      end

      def stand_alone_parse(data)
        received_header = nil
        body = "".force_encoding("ASCII-8BIT")
        completed = false

        parser = new
        parser.on_header do |header|
          received_header = header
        end
        parser.on_body do |chunk|
          body << chunk
        end
        parser.on_complete do
          completed = true
        end

        consume_data(parser, data)
        raise ParseError, "not completed: <#{data.inspect}>" unless completed

        [received_header, body]
      end

      def consume_data(parser, data)
        if data.respond_to?(:each)
          data.each do |chunk|
            parser << chunk
          end
        else
          parser << data
        end
      end
    end

    attr_reader :header
    def initialize
      reset
      initialize_hooks
    end

    def <<(chunk)
      if @header.nil?
        parse_header(chunk)
      else
        parse_body(chunk)
      end
      self
    end

    # @overload on_header(header)
    # @overload on_header {|header| }
    def on_header(*arguments, &block)
      if block_given?
        @on_header_hook = block
      else
        @on_header_hook.call(*arguments) if @on_header_hook
      end
    end

    # @overload on_body(chunk)
    # @overload on_body {|chunk| }
    def on_body(*arguments, &block)
      if block_given?
        @on_body_hook = block
      else
        @on_body_hook.call(*arguments) if @on_body_hook
      end
    end

    # @overload on_complete
    # @overload on_complete { }
    def on_complete(&block)
      if block_given?
        @on_complete_hook = block
      else
        @on_complete_hook.call if @on_complete_hook
      end
    end

    private
    def reset
      @buffer = "".force_encoding("ASCII-8BIT")
      @header = nil
      @body_size = 0
    end

    def initialize_hooks
      @on_header_hook = nil
      @on_body_hook = nil
      @on_complete_hook = nil
    end

    def parse_header(chunk)
      @buffer << chunk
      return if @buffer.bytesize < Header.size
      @header = Header.parse(@buffer)
      on_header(@header)
      buffer = @buffer
      @buffer = nil
      if buffer.bytesize > Header.size
        parse_body(buffer[Header.size..-1])
      end
    end

    def parse_body(chunk)
      @body_size += chunk.bytesize
      if @body_size < @header.size
        on_body(chunk)
      elsif @body_size == @header.size
        on_body(chunk)
        on_complete
        reset
      else
        rest_body_size = @header.size - (@body_size - chunk.bytesize)
        on_body(chunk[0, rest_body_size])
        on_complete
        reset
        self << chunk[rest_body_size..-1]
      end
    end
  end
end
