local function prequire(...)
  local ok, mod = pcall(require, ...)
  return ok and mod, ok and (...) or mod
end

local DIGEST = {}

local crypto = prequire "crypto"
if crypto then
  local digest = crypto.evp and crypto.evp.digest or crypto.digest
  if digest then 
    DIGEST.md5 = function (str) return digest("md5", str) end
  end
end

if not DIGEST.md5 and prequire "digest" and md5 then
  local md5 = md5
  DIGEST.md5 = function (str) return md5.digest(str) end
end

if not DIGEST.md5 then
  local md5 = prequire "md5"
  if md5 then 
    if md5.digest then
      DIGEST.md5 = function(str) return md5.digest(str)       end
    elseif md5.sumhexa then
      DIGEST.md5 = function(str) return md5.sumhexa(str)      end
    end
  end
end

assert(DIGEST.md5, 'can not find suported md5 module')

local s_http = require "socket.http"
local s_url = require "socket.url"
local ltn12 = require "ltn12"
local md5 = require "md5"

local hash = function(_hash, ...)
  return _hash(table.concat({...},":"))
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
  local ghost_source
  if t.source then
    local ghost_chunks = {}
    local ghost_capture = function(x)
      if x then ghost_chunks[#ghost_chunks+1] = x end
      return x
    end
    local ghost_i = 0
    ghost_source = function()
      ghost_i = ghost_i+1
      return ghost_chunks[ghost_i]
    end
    t.source = ltn12.source.chain(t.source,ghost_capture)
  end
  local b,c,h = s_http.request(t)
  if (c == 401) and h["www-authenticate"] then
    local ht = parse_header(h["www-authenticate"])
    assert(ht.realm and ht.nonce and ht.opaque)
    if ht.qop ~= "auth" then
      error(string.format("unsupported qop (%s)",tostring(ht.qop)))
    end
    local algo = ht.algorithm and ht.algorithm:lower() or 'md5'
    algo = DIGEST[algo]
    if not algo then
      error(string.format("unsupported algo (%s)",tostring(ht.algorithm)))
    end
    local nc,cnonce = "00000001",string.format("%08x",os.time())
    local uri = s_url.build{path = url.path,query = url.query}
    local method = t.method or "GET"
    local response = hash(algo,
      hash(algo,user,ht.realm,password),
      ht.nonce,
      nc,
      cnonce,
      "auth",
      hash(algo,method,uri)
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
    if t.source then t.source = ghost_source end
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
