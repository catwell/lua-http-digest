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

-- To use a local httpbin-go build, use `localhost:8080`.
local httpbin_domain = "httpbingo.org"

-- `httpbin.org` returns {authenticated = true, user = "user"} instead.
local httpbin_authenticated = {authorized = true, user = "user"}

local httpbin_route = httpbin_domain .. "/digest-auth/auth/user/passwd"
local httpbin_route_no_auth = httpbin_domain .. "/get"

local url = {
    good_creds = "http://user:passwd@" .. httpbin_route,
    bad_creds = "http://user:nawak@" .. httpbin_route,
    no_creds = "http://" .. httpbin_route,
    good_creds_no_auth = "http://user:passwd@" .. httpbin_route_no_auth,
    no_creds_no_auth = "http://" .. httpbin_route_no_auth,
}

local T = cwtest.new()
local b, c, _

T:start("basics")

-- simple interface

b, c = http_digest.request(url.good_creds)
T:eq( c, 200 )
T:eq( json_decode(b), httpbin_authenticated )

_, c = http_digest.request(url.bad_creds)
T:eq( c, 401 )

_, c = http_digest.request(url.no_creds)
T:eq( c, 401 )

b, c = http_digest.request(url.good_creds_no_auth)
T:eq( c, 200 )
T:eq( json_decode(b)["url"], url.no_creds_no_auth )

b, c = http_digest.request(url.no_creds_no_auth)
T:eq( c, 200 )
T:eq( json_decode(b)["url"], url.no_creds_no_auth )

-- generic interface

b = {}
_, c = http_digest.request {
    url = url.good_creds,
    sink = ltn12.sink.table(b),
}
T:eq( c, 200 )
b = table.concat(b)
T:eq( json_decode(b), httpbin_authenticated )

_, c = http_digest.request({url = url.bad_creds})
T:eq( c, 401 )

-- with ltn12 source

b = {}
_, c = http_digest.request {
    url = url.good_creds,
    sink = ltn12.sink.table(b),
    source = ltn12.source.string("test"),
    headers = {["content-length"] = 4}, -- 0 would work too
}
T:eq( c, 200 )
b = table.concat(b)
T:eq( select(2, b:gsub("{","")), 1 ) -- no duplicate JSON body
T:eq( json_decode(b), httpbin_authenticated )

T:done()
