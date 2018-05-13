--a table library
function tableSerialize(environment,a) --serializes a table and puts it into a string
	local str = dofile("../serialize.lua"):serialize(a)
	local ret = {}
	for c in str:gmatch(".") do
		ret[#ret] = {value = string.byte(c),isFunction=false}
	end
	return {value = ret, isFunction = false}
end
function tablePrintSerialize(environment,a)
	print(dofile("../serialize.lua"):serialize(a))
	return {value = nil, isFunction = false}
end
function tableSplit(environment,a,b) --splits a on b
	state=1
	local ret = {}
	for k,v in ipairs(a.value) do
		if state == 1 then
			ret[#ret+1] = {isFunction = false, value = {}}
			state = 2
		end
		if v.value == b.value then
			state = 1
		else
			ret[#ret].value[#ret[#ret].value+1] = shallowCopy(v)
		end
	end
	return {value = ret,isFunction = false}
end
function tableLen(environment,a)
	return {value = #a.value, isFunction = false}
end
function tableSort(environment,a)
	local values = {}
	for k,v in pairs(a.value) do
		values[k] = v.value
	end
	local sorted = table.sort(values)
	local ret = {}
	for k,v in ipairs(sorted) do
		ret[k] = {isFunction = false, value = v}
	end
	return ret
end
function tableEvery(environment,a,callback) --for everything in the table run callback on it
	for _,v in ipairs(a.value) do
		if type(callback.value) == 'function' then
			callback.value(environment,shallowCopy(v))
		else
			local scope = {_parent = environment}
			scope[callback.args[1]] = shallowCopy(v)
			run(callback.body,scope)
		end
	end
end
addGlobalFunction("SERIAL",tableSerialize)
addGlobalFunction("SERIALPRINT",tablePrintSerialize)
addGlobalFunction("SPLIT",tableSplit)
addGlobalFunction("SRT",tableSort)
addGlobalFunction("LENGTH",tableLen)
addGlobalVariable("TLINSTALLED",1)
addGlobalFunction("TLP",tableEvery)