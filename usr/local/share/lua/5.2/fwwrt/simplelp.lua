#!/usr/bin/lua

-- Simple lua (html?) pages engine
--
-- Daniel Podolsky, tpaba@cpan.org, 2009-08-04
-- Licence is the same as OpenWRT

--[[
Syntax in Lua program:
slp = fwwrt.simplelp.loadFile(fileName[, env]) -- create simplelp from file
slp = fwwrt.simplelp.loadString(text[, env])   -- create simplelp from string
--
slp:run([env]) - perform the page, return a result

Syntax inside of the file (text), load stage:
<%!fileName%>  -- tag replaced by content of named file, or by error message in case of problems
<%?fileName%>  -- tag replaced by content of named file, or by empty string in case of problems
<%:fieldName%> -- tag replaced by tostring(env.fieldName)

Syntax inside of the file (text), run stage:
<%luaExpression%>  -- perform the lua expression
<%=luaExpression%> -- preform the lua expression and replace tag with result

Syntax inside of the run-stage tags:
env.fieldName -- a field from env table passed to run() method
echo(...)     -- all the arguments are tostring()-ed added to the result
req(fileName) -- content of named file, or error message in case of problems added to the result
inc(fileName) -- content of named file, or empty string in case of problems added to the result
]]

module("fwwrt.simplelp", package.seeall)

local eol             = "\n"
local firstEolPattern = "^\r?\n"
local openTagPattern  = "<%%"
local closeTagPattern = "%%>"

local function calcFileName(param, env)
	return ((assert(loadstring("return function(env) return ("..param..") end"))())(env))
	end

function fileToVariableByName(fileName)
	local content = ""
	local file = assert(io.open(fileName, "r"), "Could not open file '"..fileName.."' for read")
	content = handlerToVariable(file)
	file:close()
	return content
end

function handlerToVariable(handler)
	return handler:read("*a")
end

local function fileToVariable(param, env)
	return fileToVariableByName(calcFileName(param, env))
	end

local includePatterns = {}
includePatterns["<%%%!%s*([^%s<%%>]+)%s*%%>"] = function(param, env)
    local success, result = pcall(fileToVariable, param, env)
	return success and result or "Could not include file '"..tostring(param).."': "..result
	end
includePatterns["<%%%?%s*([^%s<%%>]+)%s*%%>"] = function(param, env)
    local success, result = pcall(fileToVariable, param, env)
	return success and result or ""
	end
includePatterns["<%%%:%s*([^%s<%%>]+)%s*%%>"] = function(param, env)
    local success, result = pcall(fileToVariable, param)
	return tostring(env[param])
	end

local maxSubst = 100

local function recursionError()
	return string.format("!!! Error: substitution was not completed in %d turns, endless recursion suspected !!!", maxSubst)
	end

local function substByFunc(text, pattern, substFunc, env)
	local found  = false
	local result = ""

	local startSearch = 1
	local tagPosition, tagEnd, tagParam = string.find(text, pattern, startSearch)
	while (tagPosition) do
	    found  = true
		result = result..string.sub(text, startSearch, tagPosition - 1)..substFunc(tagParam, env)
	    startSearch = tagEnd + 1
	    tagPosition, tagEnd, tagParam = string.find(text, pattern, startSearch)
		end
	result = result..string.sub(text, startSearch, -1)

	return found, result
	end

local function assemble(text, env)
    local noSubst   = true
    local substTurn = 0
    repeat
        noSubst   = true
	    local pattern, func
	    for pattern, substFunc in pairs(includePatterns) do
	        local found
	        found, text = substByFunc(text, pattern, (substTurn < maxSubst) and substFunc or recursionError, env)
	        noSubst = noSubst and (not found)
	    	end
	    
	    substTurn = substTurn + 1
		until (noSubst or (substTurn > maxSubst))

    return text
	end

local function wrapStaticText(text, b, e)
    return "echo([["..(string.find(text, firstEolPattern, b) and eol or "")..string.sub(text, b, e).."]])"..eol or ""
end

local function wrapCode(text, b, e)
	if (string.sub(text, b, b) == "=") then
		return "echo("..string.sub(text, b+1, e)..")"..eol
	end

    return string.sub(text, b, e)
end

local emptyEnv = {}

function evertText(text, env)
    env  = env or emptyEnv
    text = assemble(text, env)

    local result = ""

    local startSearch = 1
    local tagPosition, tagEnd = string.find(text, openTagPattern, startSearch)

    while (tagPosition) do
    	result = result..wrapStaticText(text, startSearch, tagPosition - 1)
    	
    	startSearch = tagEnd + 1
		tagPosition, tagEnd = string.find(text, closeTagPattern, startSearch)
		
		if (not tagPosition) then
			result = result.."!!! Error: code block opened but not closed !!!"
			startSearch = -1
			break
			end
		
		result = result..wrapCode(text, startSearch, tagPosition - 1)..eol
		
    	startSearch = tagEnd + 1
		tagPosition, tagEnd = string.find(text, openTagPattern, startSearch)
    end

    result = result..wrapStaticText(text, startSearch, -1)

    return result
end

function echo(container, ...)
    local arg = table.pack(...)
	for i,a in ipairs(arg) do
		container.out = container.out..tostring(a)
		end
end

local loadstringPrefix = [[
return function(self, env)

self.out = ""

local echo = env.echo or function(...) return fwwrt.simplelp.echo(self, ...) end

local function inc(fileName) return fwwrt.simplelp.inc(fileName, env) end
local function req(fileName) return fwwrt.simplelp.req(fileName, env) end

]]

local loadstringPostfix = [[
 
end
]]

local slp_prototype_mt = {__index = {}}
slp_prototype_mt.__index.run = function(self, env)
	self:body(env)
	return self.out
	end

function loadString(str, env)
	local slp = {}
	setmetatable(slp, slp_prototype_mt)

	slp.body  = assert(loadstring(loadstringPrefix..evertText(str, env)..loadstringPostfix))()

	return slp
end

function loadFile(fileName, env)
	return loadString(fileToVariableByName(fileName), env)
	end

function doString(str, env)
	local slp = loadString(str, env)
	return slp:run(env)
end

function doFile(fileName, env)
	local slp = loadFile(fileName, env)
	return slp:run(env)
end

function req(fileName, env)
    local success, result = pcall(doFile, fileName, env)
	return success and result or "Can not include file '"..tostring(fileName).."': "..result
end

function inc(fileName, env)
    local success, result = pcall(doFile, fileName, env)
	return success and result or ""
end

