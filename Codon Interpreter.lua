--this program will interpret the codon language
local stuff = {...}
local program = table.remove(stuff,1)
local parser = dofile("parser.lua")
local prg = io.open(program,"r")
local prog = prg:read("*a")
prg:close()
function shallowCopy(value)
	local copy = {}
	for k,v in pairs(value) do
		copy[k] = v
	end
	return copy
end
local globalEnv = {
	_parent = nil, --nothing can change this from code as _ is not allowed
	ADD = {
		
		isFunction = true,
		value = function(environment,a,b)
			return {value = a.value+b.value, isFunction = false}
		end,
	},
	ST = {
		
		isFunction = true,
		value = function(environment,a,b)
			return {value = a.value-b.value, isFunction = false}
		end,
	},
	PACK = {
		isFunction = true,
		value = function(environment,...)
			local result={}
			for k,v in ipairs({...}) do
				result[k] = {value = v.value,isFunction = false}
			end
			return {value = result, isFunction = false}
		end,
	},
	PTC = {
		
		isFunction = true,
		value = function(environment,a)
			io.write(string.char(a.value))
			return {value = nil, isFunction = false}
		end,
	},
	PTN = {
		
		isFunction = true,
		value = function(environment,a,b)
			io.write(tostring(a.value))
			return {value = nil, isFunction = false}
		end,
	},
	ML = {
		
		isFunction = true,
		value = function(environment,a,b)
			return {value = a.value*b.value, isFunction = false}
		end,
	},
	DIV = {
		
		isFunction = true,
		value = function(environment,a,b)
			return {value = a.value/b.value, isFunction = false}
		end,
	},
	PRT = {
		isFunction = true,
		value = function(environment,a)
			for k,v in ipairs(a.value) do
				io.write(string.char(v.value))
			end
			return {value = nil, isFunction = false}
		end,
	},
	RST = {
		
		isFunction = true,
		value = function(env)
			local str = io.read()
			local ret = {}
			for c in str:gmatch(".") do
				ret[#ret+1] = {value = string.byte(c), isFunction = false}
			end
			return {value = ret, isFunction = false}
		end,
	},
	SRT = {
		isFunction = true,
		value = function(environment,a)
			return {value = math.sqrt(a.value),isFunction = false}
		end,
	},
	INT = {
		isFunction = true,
		value = function(environment,a)
			return {value = math.floor(a.value+0.5),isFunction = false}
		end,
	},
	MD = {
		isFunction = true,
		value = function(environment,a,b)
			return {value = a.value%b.value, isFunction = false}
		end
	},
	RNM = {
		isFunction = true,
		value = function(env)
			return {value = tonumber(io.read()),isFunction = false}
		end,
	},
	IND = {
		isFunction = true,
		value = function(environment,a,b)
			return {value = shallowCopy(a.value[b.value]),isFunction = false}
		end,
	},
	IST = {
		isFunction = true,
		value = function(environment,a)
			if type(a.value) == 'table' and not a.isFunction then
				return {value = 1, isFunction = false}
			else
				return {value = 0, isFunction = false}
			end
		end,
	},
	ISF = {
		isFunction = true,
		value = function(environment,a)
			if a.isFunction then
				return {value = 1, isFunction = false}
			else
				return {value = 0, isFunction = false}
			end
		end,
	},
	TE = {
		isFunction = true,
		value = function(environment,a,b)
			if type(a.value) == 'table' and type(b.value) == 'table' then
				local function deepcompare(t1,t2,ignore_mt)
					local ty1 = type(t1)
					local ty2 = type(t2)
					if ty1 ~= ty2 then return false end
					-- non-table types can be directly compared
					if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
					-- as well as tables which have the metamethod __eq
					local mt = getmetatable(t1)
					if not ignore_mt and mt and mt.__eq then 
						return t1 == t2 
					end
					for k1,v1 in pairs(t1) do
						local v2 = t2[k1]
						if v2 == nil or not deepcompare(v1,v2) then return false end
					end
					for k2,v2 in pairs(t2) do
						local v1 = t1[k2]
						if v1 == nil or not deepcompare(v1,v2) then return false end
					end
					return true
				end
				if deepcompare(a.value,b.value) then
					return {value = 1, isFunction = false}
				else
					return {value = 0, isFunction = false}
				end
			else
				return {value = 0, isFunction = false}
			end
		end,
	},
	R = {
		isFunction = true,
		value = function(environment,a,b)
			if a >= 1 or b >= 1 then
				return {value = 1, isFunction = false}
			end
			return {value = 0, isFunction = false}
		end,
	},
	AND = {
		isFunction = true,
		value = function(environment,a,b)
			if a >= 1 and b >= 1 then
				return {value = 1, isFunction = false}
			end
			return {value = 0, isFunction = false}
		end,
	},
	NE = {
		isFunction = true,
		value = function(environment,a,b)
			if a ~= b then
				return {value = 1, isFunction = false}
			end
			return {value = 0, isFunction = false}
		end,
	},
	E = {
		isFunction = true,
		value = function(environment,a,b)
			if a == b then
				return {value = 1, isFunction = false}
			end
			return {value = 0, isFunction = false}
		end,
	},
	LT = {
		isFunction = true,
		value = function(environment,a,b)
			if a < b then
				return {value = 1, isFunction = false}
			end
			return {value = 0, isFunction = false}
		end,
	},
	GT = {
		isFunction = true,
		value = function(environment,a,b)
			if a > b then
				return {value = 1, isFunction = false}
			end
			return {value = 0, isFunction = false}
		end,
	},
	LE = {
		isFunction = true,
		value = function(environment,a,b)
			if a <= b then
				return {value = 1, isFunction = false}
			end
			return {value = 0, isFunction = false}
		end,
	},
	GE = {
		isFunction = true,
		value = function(environment,a,b)
			if a >= b then
				return {value = 1, isFunction = false}
			end
			return {value = 0, isFunction = false}
		end,
	},
	TN = {
		isFunction = true,
		value = function(environment,a)
			str = ""
			for k,v in ipairs(a.value) do
				str = str..string.char(v)
			end
			return {value = tonumber(str),isFunction = false}
		end,
	},
	TS = {
		isFunction = true,
		value = function(environment,a)
			str = tostring(a.value)
			local ret = {}
			for c in str:gmatch(".") do
				ret[#ret] = {value = string.byte(c),isFunction=false}
			end
			return {value = ret, isFunction = false}
		end,
	},
	PI = {
		isFunction = false,
		value = math.pi
	},
	KE = {
		isFunction = false,
		value = math.exp(1),
	},
	TPI = {
		isFunction = false,
		value = math.pi * 2
	},
	T = {
		isFunction = false,
		value = 1
	},
	F = {
		isFunction = false,
		value = 0
	},
	NIL = {
		isFunction = false,
		value = nil
	},
	CCAT = {
		isFunction = true,
		value = function(environment,...)
			local tabs = {...}
			local resTab = {isFunction = false,value={}}
			for k,v in ipairs(tabs) do
				if type(v.value) == 'table' then
					for k2,v2 in ipairs(v.value) do
						local insertable = shallowCopy(v2)
						resTab.value[#resTab.value] = insertable
					end
				else
					resTab.value[#resTab.value] = shallowCopy(v)
				end
			end
			return resTab
		end,
	},
	LENGTH = {
		isFunction = true,
		value = function(a)
			return {value = #a.value, isFunction = false}
		end,
	},
}
function addGlobalFunction(key,value)
	globalEnv[key] = {isFunction = true, value = value}
end
function addGlobalVariable(key,value)
	globalEnv[key] = {isFunction = false, value = value}
end
for k,v in pairs(stuff) do
	--load libraries
	dofile(v) --adds stuff to global environment if they do it correctly
end
function getVariable(environment,variable) --returns a shallow copy of the variable
	if environment[variable] then
		return shallowCopy(environment[variable])
	else
		if environment._parent then
			return getVariable(environment._parent,variable)
		else
			return {isFunction = false, value = nil}
		end
	end
end
function setVariable(environment,variable,value) --sets it to a shallow copy of the value
	local copy = shallowCopy(value)
	if environment[variable] then
		environment[variable] = copy
	else
		if environment._parent then
			setVariable(environment._parent,variable,value)
		else
			error("Trying to set undefined variable: "..variable.."\nto value: "..value.value)
		end
	end
end
function setVariableIndex(environment,variable,index,value) --again sets it to a shallow copy
	local copy = shallowCopy(value)
	if environment[variable] then
		environment[variable].value[index.value] = copy
	else
		if environment._parent then
			setVariable(environment._parent,variable,value)
		else
			error("Trying to set undefined table: "..variable.."\nindex: "..index.value.."\nvalue"..value.value)
		end
	end
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function run(tree,environment)
	tree = deepcopy(tree) --make sure it does not change values in it forever
	for k,v in ipairs(tree) do
		if #v and not v.t then
			tree[k],isBreaking,isReturning = run(v,{_parent = environment})
			if isBreaking or isReturning then
				return tree[k],isBreaking,isReturning
			end
		elseif v.t == "definitionMethod" then
			if not v.isGlobal then
				environment[v.name] = {isFunction = true, value = {args = v.args, body = v.body}}
			else
				globalEnv[v.name] = {isFunction = true, value = {args = v.args, body = v.body}}
			end
			tree[k] = {isFunction = false, value = nil}
		elseif v.t == "definitionVariable" then
			if not v.isGlobal then
				environment[v.name] = {isFunction = false,value = nil}
			else
				globalEnv[v.name] = {isFunction = false,value = nil}
			end
			tree[k] = {isFunction = false, value = nil}
		elseif v.t == "definitionVariableTable" then
			if not v.isGlobal then
				environment[v.name] = {isFunction = false,value = {}}
			else
				globalEnv[v.name] = {isFunction = false,value = {}}
			end
			tree[k] = {isFunction = false, value = nil}
		elseif v.t == "assignmentVariable" then
			local name = v.name
			local value,isBreaking,isReturning = run(v.body,{_parent = environment})
			if isBreaking or isReturning then
				error("Cannot break or return in assignment to "..v.name)
			end
			setVariable(environment,name,value)
			tree[k] = {isFunction = false, value = nil}
		elseif v.t == "assignmentTableIndex" then
			local name = v.name
			local index,isBreaking,isReturning = run(v.index,{_parent = environment})
			if isBreaking or isReturning then
				error("Cannot break or return in assignment to "..v.name)
			end
			local value,isBreaking,isReturning = run(v.body,{_parent = environment})
			if isBreaking or isReturning then
				error("Cannot break or return in assignment to "..v.name)
			end
			if type(index.value) == 'table' then
				error("Trying to use a table as an index")
			end
			setVariableIndex(environment,name,index,value)
			tree[k] = {isFunction = false, value = nil}
		elseif v.t == "methodCall" then
			--this requires the creation of a new scope
			local name = v.name
			local method = getVariable(environment,name)
			if method.value == nil then
				error("Trying to call non-extant function: "..name)
			elseif method.isFunction == false then
				error(name.." is not a method")
			end
			--get the arguments
			local argVals = {}
			for k2,v2 in ipairs(v.args) do
				argVals[k2],isBreaking,isReturning = run(v2,{_parent = environment})
				argVals[k2] = shallowCopy(argVals[k2]) --use a shallow copy so inside table references are preserved
				if isBreaking or isReturning then
					error("Cannot break or return in an argument for function: "..v.name)
				end
			end
			if type(method.value) == "function" then
				--library function
				tree[k] = method.value(environment,unpack(argVals))
			else
				--user defined function
				local method = method.value
				local methodScope = {_parent = environment} --creating the function scope
				if #argVals ~= #method.args then
					error("Wrong number of arguments for call to "..v.name..'\nExpected: '..#method.args..'\nGot: '..#argVals)
				end
				for k2,v2 in ipairs(method.args) do
					scope[v2] = argVals[k2]
				end
				tree[k],isBreaking,isReturning = run(method.body,methodScope)
				if isBreaking then
					error("Cannot break out of a non-existing while loop\nIn method: "..v.name)
				end
			end
		elseif v.t == "getVariable" then
			local name = v.name
			tree[k] = getVariable(environment,name)
		elseif v.t == "constant" then
			tree[k] = {isFunction = false,v.value}
		elseif v.t == "unpack" then
			local name = v.name
			local tab = getVariable(environment,name)
			if type(tab.value) ~= "table" then
				error("Trying to unpack "..name.." which is a "..type(tab.value).." not a table")
			end
			if tab.isFunction then
				error("Trying to unpack "..name.." which is a function not a table")
			end
			for k2,v2 in ipairs(tab.value) do
				setVariable(environment,toVars[k2],v2)
			end
			tree[k] = {isFunction = false, value = nil}
		elseif v.t == "if" then
			local condition = v.condition
			local result,isBreaking,isReturning = run(condition,{_parent = environment})
			if isBreaking or isReturning then
				error("Cannot return or break in a condition")
			end
			if result.isFunction then
				error("Cannot use a function as a condition")
			end
			if type(result.value) == 'table' then
				error("Cannot use a table as a condition")
			end
			if result.value and result.value >= 1 then
				tree[k],isBreaking,isReturning = run(v.body,{_parent = environment})
				if isBreaking or isReturning then
					return tree[k],isBreaking,isReturning
				end
			else
				tree[k],isBreaking,isReturning = run(v.elsebody,{_parent = environment})
				if isBreaking or isReturning then
					return tree[k],isBreaking,isReturning
				end
			end
		elseif v.t == "while" then
			local condition = v.condition
			while true do
				local result,isBreaking,isReturning = run(condition,{_parent = environment})
				if isBreaking or isReturning then
					error("Cannot return or break in a condition")
				end
				if result.isFunction then
					error("Cannot use a function as a condition")
				end
				if type(result.value) == 'table' then
					error("Cannot use a table as a condition")
				end
				if result.value and result.value >= 1 then
					_,isBreaking,isReturning = run(v.body,{_parent = environment})
					if isBreaking then
						break
					end
					if isReturning then
						return tree[k],isBreaking,isReturning
					end
				else
					break
				end
			end
			tree[k] = {isFunction = false, value = nil}
		elseif v.t == "break" then
			return {isFunction = false, value = nil},true,false
		elseif v.t == "return" then
			local value,isBreaking = run(v.body,{_parent = environment})
			if isBreaking then error("Breaking out of a non-extant while loop") end
			return value,false,true
		end
	end
	return (tree[#tree] or {isFunction = false, value = nil}),false,false
end
run(parser(prog),globalEnv)
