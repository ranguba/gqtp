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
  class Parser
    def initialize
      @data = "".force_encoding("ASCII-8BIT")
      @header = nil
      @body_size = 0
      @completed = false
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

    def completed?
      @completed
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
    def initialize_hooks
      @on_header_hook = nil
      @on_body_hook = nil
      @on_complete_hook = nil
    end

    def parse_header(chunk)
      @data << chunk
      return if @data.bytesize < Header.size
      @header = Header.parse(@data)
      on_header(@header)
      if @data.bytesize > Header.size
        parse_body(@data[Header.size, -1])
      end
      @data = nil
    end

    def parse_body(chunk)
      raise "already completed." if @completed
      @body_size += chunk.bytesize
      on_body(chunk)
      if @body_size >= @header.size
        @completed = true
        on_complete
      end
    end
  end
end
