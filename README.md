# http-digest

## Presentation

Small implementation of HTTP Digest Authentication (client-side) in Lua
that mimics the API of LuaSocket.

Only supports auth/MD5, no reuse of client nonce, pull requests welcome.

## Dependencies

- luasocket
- md5

Tests require [cwtest](https://github.com/catwell/cwtest), a JSON parser
and the availability of [httpbin.org](http://httpbin.org).

## Usage

See [LuaSocket](http://w3.impa.br/~diego/software/luasocket/http.html)'s
`http.request`. Credentials must be contained in the URL. Both the simple and
generic interface are supported. Here is an example with the simple interface:

```lua
local http_digest = require "http-digest"
local url = "http://user:passwd@httpbin.org/digest-auth/auth/user/passwd"
local b, c, h = http_digest.request(url)
```

See the tests for more.

Other compatible http clients (like Copas or LuaSec) can be used as well. To use
another http client replace the default one:

```lua
local http_digest = require "http-digest"
http_digest.http = require "copas.http"
```

## Note

If you get this error when running the tests, update LuaSocket:

    variable 'PROXY' is not declared

You may need to use the SCM version to run them (see
[this issue](https://github.com/diegonehab/luasocket/issues/110)).

This only impacts the tests, the code itself works with older versions as well.

## Copyright

- Copyright (c) 2012-2013 Moodstocks SAS
- Copyright (c) 2014-2022 Pierre Chapuis

## Changelog

### x.x unreleased

- fix: drop initial 401 response body instead of concatenating both responses
- feat: made the http client configurable to be able to use Copas or LuaSec clients
