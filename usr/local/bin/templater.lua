#!/usr/bin/lua

require "fwwrt.simplelp"

local osEnv = {}
for line in io.popen("set"):lines() do 
  envName = line:match("^[^=]+")
  osEnv[envName] = os.getenv(envName)
end

print(fwwrt.simplelp.doString(fwwrt.simplelp.handlerToVariable(io.stdin), osEnv))