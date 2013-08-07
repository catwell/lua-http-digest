local function prequire(...)
  local ok, mod = pcall(require, ...)
  return ok and mod, ok and (...) or mod
end

local cwtest = require "cwtest"
local ltn12 = require "ltn12"
local J = assert((prequire "json") or (prequire "cjson")).decode
local H = (require "http-digest").request

local T = cwtest.new()

local b,c,h
local url = "http://user:passwd@httpbin.org/digest-auth/auth/user/passwd"
local badurl = "http://user:nawak@httpbin.org/digest-auth/auth/user/passwd"

T:start("basics")

-- simple interface

b,c,h = H(url)
T:eq( c, 200 )
T:eq( J(b), {authenticated = true,user = "user"} )

b,c,h = H(badurl)
T:eq( c, 401 )

-- generic interface

b = {}
_,c,h = H{
  url = url,
  sink = ltn12.sink.table(b),
}
T:eq( c, 200 )
b = table.concat(b)
T:eq( J(b), {authenticated = true,user = "user"} )

_,c,h = H{url = badurl}
T:eq( c, 401 )

-- with ltn12 source

b = {}
_,c,h = H{
  url = url,
  sink = ltn12.sink.table(b),
  source = ltn12.source.string("test"),
  headers = {["content-length"] = 4}, -- 0 would work too
}
T:eq( c, 200 )
b = table.concat(b)
T:eq( J(b), {authenticated = true,user = "user"} )

T:done()
