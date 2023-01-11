# http-digest

![CI Status](https://github.com/catwell/lua-http-digest/actions/workflows/ci.yml/badge.svg?branch=master)

## Presentation

Small implementation of HTTP Digest Authentication (client-side) in Lua
that mimics the API of LuaSocket.

Only supports auth/MD5, no reuse of client nonce, pull requests welcome.

## Dependencies

- luasocket
- md5

Tests require [cwtest](https://github.com/catwell/cwtest), a JSON parser
and the availability of [httpbingo.org](http://httpbingo.org).

## Usage

See [LuaSocket](http://w3.impa.br/~diego/software/luasocket/http.html)'s
`http.request`. Credentials must be contained in the URL. Both the simple and
generic interface are supported. Here is an example with the simple interface:

```lua
local http_digest = require "http-digest"
local url = "http://user:passwd@httpbingo.org/digest-auth/auth/user/passwd"
local b, c, h = http_digest.request(url)
```

See the tests for more.

Other compatible http clients (like Copas or LuaSec) can be used as well. To use
another http client replace the default one:

```lua
local http_digest = require "http-digest"
http_digest.http = require "copas.http"
```

## Copyright

- Copyright (c) 2012-2013 Moodstocks SAS
- Copyright (c) 2014-2022 Pierre Chapuis

## Changelog

### x.x unreleased

- fix: drop initial 401 response body instead of concatenating both responses
- feat: also allow unauthenticated requests. Only check for creds if they are
  needed. If not provided return the original 401 response.
- feat: made the http client configurable to be able to use Copas or LuaSec clients
