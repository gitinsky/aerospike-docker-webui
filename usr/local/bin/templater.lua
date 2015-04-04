#!/usr/bin/lua

require "fwwrt.simplelp"

print(fwwrt.simplelp.doString(fwwrt.simplelp.handlerToVariable(io.stdin), {}))