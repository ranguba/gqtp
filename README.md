# README

## Name

gqtp

## Description

Gqtp gem is a
[GQTP (Groonga Query Transfer Protocol)](http://groonga.org/docs/spec/gqtp.html)
Ruby implementation.

Gqtp gem provides both GQTP client, GQTP server and GQTP proxy
implementations. They provide asynchronous API. You can use gqtp gem
for high concurrency use.

## Install

    % gem install gqtp

## Usage

### Client

    client = GQTP::Client.new(:host => "192.168.0.1", :port => 10043)
    request = client.send("status") do |header, body|
      p body # => "{\"alloc_count\":163,...}"
    end
    request.wait

### Server

    server = GQTP::Server.new(:host => "192.168.0.1", :port => 10043)
    server.on_request do |request, client|
      body = "{\"alloc_count\":163,...}"
      header = GQTP::Header.new
      header.query_type = GQTP::Header::ContentType::JSON
      header.flags = GQTP::Header::Flag::TAIL
      header.size = body.bytesize
      client.write(header.pack, body) do
        client.close
      end
    end
    server.run.wait

### Proxy

    proxy = GQTP::Proxy.new(:listen_host => "127.0.0.1",
                            :listen_port => 10043,
                            :upstream_host => "192.168.0.1",
                            :upstream_port => 10043)
    proxy.run.wait

## Dependencies

* Ruby 1.9.3

## Mailing list

* English: [groonga-talk@lists.sourceforge.net](https://lists.sourceforge.net/lists/listinfo/groonga-talk)
* Japanese: [groonga-dev@lists.sourceforge.jp](http://lists.sourceforge.jp/mailman/listinfo/groonga-dev)

## Thanks

* ...

## Authors

* Kouhei Sutou \<kou@clear-code.com\>

## License

LGPLv2.1 or later. See doc/text/lgpl-2.1.txt for details.

(Kouhei Sutou has a right to change the license including contributed
patches.)
