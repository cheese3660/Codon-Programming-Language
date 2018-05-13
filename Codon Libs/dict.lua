--A dictionary library for codon
local function deepcompare(environment,t1,t2,ignore_mt)
	local ty1 = type(t1)
	local ty2 = type(t2)
	if ty1 ~= ty2 then return false end
	-- non-table types can be directly compared
	if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
	-- as well as tables which have the metamethod __eq
	local mt = getmetatable(t1)
	if not ignore_mt and mt and mt.__eq then return t1 == t2 end
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
function setEntry(environment,dictionary,key,value)
	local pointer = 1
	while true do
		if pointer > #dictionary.value then
			break
		end
		correctI = deepcompare(key.value,dictionary.value[pointer].value)
		if correctI then
			dictionary.value[pointer+1] = value
			return {isFunction = false, value = nil}
		end
		pointer = pointer+2
	end
	dictionary.value[pointer] = key
	dictionary.value[pointer+1] = value
	return {isFunction = false, value = nil}
end
function getEntry(environment,dictionary,key)
	local pointer = 1
	while true do
		if pointer > #dictionary.value then
			break
		end
		correctI = deepcompare(key.value,dictionary.value[pointer].value)
		if correctI then
			return shallowCopy(dictionary.value[pointer+1])
		end
		pointer = pointer+2
	end
	return {isFunction = false, value = nil}
end
function dictPairs(environment,dictionary,callback) --runs a loop on every object in a dictionary
	local state = 1 
	local result = {}
	for k,v in pairs(dictionary.value) do
		if state = 1 then
			result[#result+1] = {shallowCopy(v)}
			state = 2
		else
			result[#result][2] = shallowCopy(v)
			state = 1
		end
	end
	for k,v in pairs(result) do
		if type(callback.value) == 'function' then
			callback.value(environment,k,shallowCopy(v))
		else
			local scope = {_parent = environment}
			scope[callback.args[1]] = {value = k, isFunction = false}
			scope[callback.args[2]] = shallowCopy(v)
			run(callback.body,scope)
		end
	end
	return {isFunction = false, value = nil}
end
addGlobalFunction("SETENTRI",setEntry)
addGlobalFunction("GETENTRI",getEntry)
addGlobalFunction("PAIRS",dictPairs)
addGlobalVariable("DICTINSTALLED",1)