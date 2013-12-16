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

require "socket"

require "gqtp/client"

class ClientTest < Test::Unit::TestCase
  def setup
    @address = "127.0.0.1"
    @server = TCPServer.new(@address, 0)
    @port = @server.addr[1]

    @request_body = nil
    @response_body = nil
    @thread = Thread.new do
      client = @server.accept
      @server.close

      process_client(client)

      client.close
    end
  end

  def teardown
    @thread.kill
  end

  def test_sync
    @response_body = "[false]"
    client = GQTP::Client.new(:address => @address, :port => @port)
    client.send("status")
    header, body = client.read
    assert_equal(["status",      @response_body.bytesize, @response_body],
                 [@request_body, header.size,             body])
  end

  def test_async
    @response_body = "[false]"
    client = GQTP::Client.new(:address => @address, :port => @port)
    request = client.send("status") do |header, body|
      assert_equal(["status",      @response_body.bytesize, @response_body],
                   [@request_body, header.size,             body])
    end
    request.wait
  end

  private
  def process_client(client)
    header = GQTP::Header.parse(client.read(GQTP::Header.size))
    @request_body = client.read(header.size)

    response_header = GQTP::Header.new
    response_header.size = @response_body.bytesize
    client.write(response_header.pack)
    client.write(@response_body)
  end

  class CloseTest < self
    def test_sync
      @response_body = "[]"
      client = GQTP::Client.new(:address => @address, :port => @port)
      assert_true(client.close)
    end

    def test_async
      @response_body = "[]"
      client = GQTP::Client.new(:address => @address, :port => @port)
      closed = false
      close_request = client.close do
        closed = true
      end
      assert_false(closed)
      close_request.wait
      assert_true(closed)
    end
  end
end
