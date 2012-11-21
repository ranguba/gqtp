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

require "gqtp/server"

Thread.abort_on_exception = true

server = GQTP::Server.new
server.on_request do |request, client|
  body = "{\"alloc_count\":163,\"starttime\":1353510048,\"uptime\":117,\"version\":\"2.0.8-19-g114f394\",\"n_queries\":0,\"cache_hit_rate\":0.0,\"command_version\":1,\"default_command_version\":1,\"max_command_version\":2}"
  header = GQTP::Header.new
  header.query_type = GQTP::Header::ContentType::JSON
  header.flags = GQTP::Header::Flag::TAIL
  header.size = body.bytesize
  client.write(header.pack, body) do
    client.close
  end
end
server.run.wait
