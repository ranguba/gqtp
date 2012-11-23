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

class ParserTest < Test::Unit::TestCase
  def setup
    @parser = GQTP::Parser.new
  end

  def test_on_header
    received_header = nil
    @parser.on_header do |header|
      received_header = header
    end

    header = GQTP::Header.new
    packed_header = header.pack
    @parser << packed_header[0..-2]
    assert_nil(received_header)
    @parser << packed_header[-1..-1]
    assert_equal(header, received_header)
  end

  def test_on_body
    received_data = ""
    @parser.on_body do |chunk|
      received_data << chunk
    end

    data = "status"
    header = GQTP::Header.new
    header.size = data.bytesize

    @parser << header.pack
    assert_equal("", received_data)

    @parser << data[0..-2]
    assert_equal(data[0..-2], received_data)

    @parser << data[-1..-1]
    assert_equal(data, received_data)
  end

  def test_on_complete
    completed = false
    @parser.on_complete do
      completed = true
    end

    data = "status"
    header = GQTP::Header.new
    header.size = data.bytesize

    @parser << header.pack << data[0..-2]
    assert_false(completed)

    @parser << data[-1..-1]
    assert_true(completed)
  end

  def test_complete?
    data = "status"
    header = GQTP::Header.new
    header.size = data.bytesize

    @parser << header.pack << data[0..-2]
    assert_false(@parser.completed?)

    @parser << data[-1..-1]
    assert_true(@parser.completed?)
  end

  class ParseTest < self
    def test_event
      body = "status"
      header = GQTP::Header.new
      header.size = body.bytesize

      events = []
      GQTP::Parser.parse([header.pack, body]) do |event_type, *arguments|
        events << [event_type, arguments]
      end
      assert_equal([
                     [:on_header,   [header]],
                     [:on_body,     [body]],
                     [:on_complete, []],
                   ],
                   events)
    end

    class StandAloneTest < self
      def test_success
        body = "status"
        header = GQTP::Header.new
        header.size = body.bytesize

        parsed_header, parsed_body = GQTP::Parser.parse([header.pack, body])
        assert_equal([       header,        body],
                     [parsed_header, parsed_body])
      end

      def test_not_completed
        header = GQTP::Header.new
        not_completed_data = header.pack[0..1]

        message = "not completed: <#{not_completed_data.inspect}>"
        exception = GQTP::ParseError.new(message)
        assert_raise(exception) do
          GQTP::Parser.parse(not_completed_data)
        end
      end
    end
  end
end
