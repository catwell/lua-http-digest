local s_http = require "socket.http"
local s_url = require "socket.url"
local ltn12 = require "ltn12"
local md5 = require "md5"

local hash = function(...)
  return md5.sumhexa(table.concat({...},":"))
end

local parse_header = function(h)
  local r = {}
  for k,v in (h .. ','):gmatch("(%w+)=(.-),") do
    if v:sub(1,1) == '"' then -- strip quotes
      r[k:lower()] = v:sub(2,-2)
    else r[k:lower()] = v end
  end
  return r
end

local make_digest_header = function(t)
  local s = {}
  for k,v in pairs(t) do
    s[#s+1] = k .. '="' .. v .. '"'
  end
  return "Digest " .. table.concat(s,', ')
end

local hcopy = function(t)
  local r = {}
  for k,v in pairs(t) do r[k] = v end
  return r
end

local _request = function(t)
  if not t.url then error("missing URL") end
  local url = s_url.parse(t.url)
  local user,password = url.user,url.password
  if not (user and password) then
    error("missing credentials in URL")
  end
  url.user,url.password,url.authority,url.userinfo = nil,nil,nil,nil
  t.url = s_url.build(url)
  local b,c,h = s_http.request(t)
  if (c == 401) and h["www-authenticate"] then
    local ht = parse_header(h["www-authenticate"])
    assert(ht.realm and ht.nonce and ht.opaque)
    if ht.qop ~= "auth" then
      error(string.format("unsupported qop (%s)",tostring(ht.qop)))
    end
    if ht.algorithm and (ht.algorithm:lower() ~= "md5") then
      error(string.format("unsupported algo (%s)",tostring(ht.algorithm)))
    end
    local nc,cnonce = "00000001",string.format("%08x",os.time())
    local uri = s_url.build{path = url.path,query = url.query}
    local method = t.method or "GET"
    local response = hash(
      hash(user,ht.realm,password),
      ht.nonce,
      nc,
      cnonce,
      "auth",
      hash(method,uri)
    )
    t.headers = t.headers or {}
    t.headers.authorization = make_digest_header{
      username = user,
      realm = ht.realm,
      uri = uri,
      nonce = ht.nonce,
      nc = nc,
      cnonce = cnonce,
      algorithm = "MD5",
      qop = "auth",
      response = response,
      opaque = ht.opaque,
    }
    b,c,h = s_http.request(t)
    return b,c,h
  else return b,c,h end
end

local request = function(x)
  local _t = type(x)
  if _t == "table" then
    return _request(hcopy(x))
  elseif _t == "string" then
    local r = {}
    local _,c,h = _request{url = x,sink = ltn12.sink.table(r)}
    return table.concat(r),c,h
  else error(string.format("unexpected type %s",_t)) end
end

return {
  request = request,
}
