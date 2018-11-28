local cwtest = require "cwtest"
local ltn12 = require "ltn12"
local http_digest = require "http-digest"

local json_decode
do -- Find a JSON parser
    local ok, json = pcall(require, "cjson")
    if not ok then ok, json = pcall(require, "json") end
    json_decode = json.decode
    assert(ok and json_decode, "no JSON parser found :(")
end

local T = cwtest.new()

local b, c, _
local url = "http://user:passwd@httpbin.org/digest-auth/auth/user/passwd"
local badurl = "http://user:nawak@httpbin.org/digest-auth/auth/user/passwd"

T:start("basics")

-- simple interface

b, c = http_digest.request(url)
T:eq( c, 200 )
T:eq( json_decode(b), {authenticated = true, user = "user"} )

_, c = http_digest.request(badurl)
T:eq( c, 401 )

-- generic interface

b = {}
_, c = http_digest.request {
    url = url,
    sink = ltn12.sink.table(b),
}
T:eq( c, 200 )
b = table.concat(b)
T:eq( json_decode(b), {authenticated = true, user = "user"} )

_, c = http_digest.request({url = badurl})
T:eq( c, 401 )

-- with ltn12 source

b = {}
_, c = http_digest.request {
    url = url,
    sink = ltn12.sink.table(b),
    source = ltn12.source.string("test"),
    headers = {["content-length"] = 4}, -- 0 would work too
}
T:eq( c, 200 )
b = table.concat(b)
T:eq( json_decode(b), {authenticated = true, user = "user"} )

T:done()
