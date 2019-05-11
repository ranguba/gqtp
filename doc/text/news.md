# News

## 1.0.7: 2019-05-11

### Improvements

  * Added support for `Groonga::Client#close` after sending `shutdown`
    or `close`.

## 1.0.6: 2014-03-25

### Improvements

  * Added EventMachine backend.

### Changes

  * Changed the default port number to 10043 from 10041 because GQTP
    server packages use 10043.
  * Changed error class when unknown connection type is specified to
    `GQTP::Client.new` to `ArgumentError` from `RuntimeError`.
  * Wrapped internal error to `GQTP::ConnectionError`.
  * Changed `:address` keyword to `:host` in `GQTP::Client.new`.
    `:address` is still usable but it is deprecated.
  * Changed connection backend module/directory name to `backend` from
    `connection`.

## 1.0.5: 2013-09-18

### Improvements

  * Supported async close.

## 1.0.4: 2013-07-08

### Fixes

  * Fixed missing synchronization bug
  * Suppressed warnings

## 1.0.3: 2013-01-07

### Fixes

  * Fixed the bug anyone can't see README document in rubydoc.info.
    README URL: http://rubydoc.info/gems/gqtp/

## 1.0.2: 2012-12-29

### Fixes

  * Added missing file for documentaion.

## 1.0.1: 2012-12-29

### Improvements

  * [client] Sent
    [quit command](http://groonga.org/docs/reference/commands/quit.html)
    on close.

## 1.0.0: 2012-11-29

The first release!!!
