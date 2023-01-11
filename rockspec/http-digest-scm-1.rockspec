rockspec_format = "3.0"

package = "http-digest"
version = "scm-1"

source = {
    url = "git://github.com/catwell/lua-http-digest.git",
}

description = {
    summary = "Client side HTTP Digest Authentication",
    detailed = [[
        Small implementation of client-side HTTP Digest Authentication
        that mimics the API of LuaSocket.
        Only supports auth/MD5, no reuse of client nonce.
    ]],
    homepage = "https://github.com/catwell/lua-http-digest",
    license = "MIT/X11",
}

dependencies = {
    "lua >= 5.1",
    "luasocket",
    "md5", -- or crypto, or digest
}

build = {
    type = "none",
    install = { lua = { ["http-digest"] = "http-digest.lua" } },
    copy_directories = {},
}

test_dependencies = {
    "cwtest",
    "luajson",
    "copas",
    "luasocket >= 3.1", -- see https://github.com/lunarmodules/copas/issues
}

test = {
   type = "command",
   script = "http-digest.test.lua",
}
