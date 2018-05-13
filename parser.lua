--This is a function that parses the codon language
function compressProgram(program)
	compressed = ""
	for v in string.gmatch(program,"[^\r\n]+") do
		if v:find(';') then
			v = v:sub(1,v:find(';')-1)
		end
		compressed = compressed..v
	end
	local compressed = compressed:gsub("%s","")
	return compressed
end
function normalizeConstant(const)
	local ctab = {
		A='0',
		C='1',
		D='2',
		E='3',
		F='4',
		G='5',
		H='6',
		I='7',
		K='8',
		L='9',
		M='A',
		N='B',
		P='C',
		T='D',
		R='E',
		S='F',
		T='N',
	}
	local converted = ""
	for i in const:gmatch('.') do
		if not ctab[i] then
			error("Unexpected acid "..i.." in constant "..const)
		end
		converted = converted..ctab[i]
	end
	return tonumber(converted,16)
end
function normalizeFloatingConstant(const)
	local ctab = {
		A='0',
		C='1',
		D='2',
		E='3',
		F='4',
		G='5',
		H='6',
		I='7',
		K='8',
		L='9',
		M='.',
		N='-',
	}
	local converted = ""
	for i in const:gmatch('.') do
		if not ctab[i] then
			error("Unexpected acid "..i.." in constant "..const)
		end
		converted = converted..ctab[i]
	end
	return tonumber(converted)
end
function table_print (tt, indent, done)
  done = done or {}
  indent = indent or 0
  if type(tt) == "table" then
    for key, value in pairs (tt) do
      io.write(string.rep (" ", indent)) -- indent it
      if type (value) == "table" and not done [value] then
        done [value] = true
        io.write(string.format("[%s] => table\n", tostring (key)));
        io.write(string.rep (" ", indent+4)) -- indent it
        io.write("(\n");
        table_print (value, indent + 7, done)
        io.write(string.rep (" ", indent+4)) -- indent it
        io.write(")\n");
      else
        io.write(string.format("[%s] => %s\n",
            tostring (key), tostring(value)))
      end
    end
  else
    io.write(tt .. "\n")
  end
end
function parse(expression)
	local parsed = {}
	local acidRegex="[CHIMSVAGLPTRFWDNEK]"
	if expression:sub(1,1) == 'M' then
		expression = expression:sub(2,-1)
	end
	while expression ~= "*" and expression ~= "Y" and expression ~= "" do
		
		if expression:sub(2,2) == "D" and (expression:sub(1,1) == "G" or expression:sub(1,1) == "L")then
			parsed[#parsed+1] = {t="definition"}
			if expression:sub(1,1) == "G" then
				parsed[#parsed].isGlobal = true
			else
				parsed[#parsed].isGlobal = false
			end
			location = #parsed
			if expression:sub(3,3) == "M" then
				parsed[location].t = "definitionMethod"
				parsed[location].name = expression:sub(4,expression:find('%*')-1)
				expression = expression:sub(expression:find('%*')+1,-1)
				local argumentEnd = expression:find("%*%*")
				local argumentString = expression:sub(1,argumentEnd)
				local arguments = {}
				while argumentString ~= "" do
					if argumentString:sub(1,1) == "A" then
						table.insert(arguments,argumentString:sub(2,argumentString:find("%*")-1))
						argumentString = argumentString:sub(argumentString:find("%*")+1,-1)
					end
				end
				parsed[location].args = arguments
				--find the end of the custom method
				expression = expression:sub(argumentEnd+3,-1)
				local level = 1
				local found = false
				local position = 0
				for i = 1, expression:len() do
					if expression:sub(i,i) == "Q" then
						level = level + 1
					elseif expression:sub(i,i) == "Y" then
						level = level - 1
					end
					if level == 0 then
						found = true
						position = i
						break
					end
				end
				if not found then
					error("Method definition for "..parsed[location].name.." does not end")
				end
				parsed[location].body = parse(expression:sub(1,position))
				expression = expression:sub(position+2,-1)
			elseif expression:sub(3,3) == "V" then
				parsed[location].t = "definitionVariable"
				parsed[location].name = expression:sub(4,expression:find('%*')-1)
				expression = expression:sub(expression:find('%*')+1,-1)
			elseif expression:sub(3,3) == "T" then
				parsed[location].t = "definitionVariableTable"
				parsed[location].name = expression:sub(4,expression:find('%*')-1)
				expression = expression:sub(expression:find('%*')+1,-1)
			else
				error("Invalid definition type: "..expression:sub(2,2))
			end
			
		elseif expression:sub(1,1) == "S" then
			parsed[#parsed+1] = {t = "assignment"}
			local location = #parsed
			if expression:sub(2,2) == "V" then
				parsed[location].t = "assignmentVariable"
				parsed[location].name = expression:sub(3,expression:find('%*')-1)
				expression = expression:sub(expression:find('%*')+2,-1)
				--find end of assignment
				local level = 1
				local found = false
				local position = 0
				for i = 1, expression:len() do
					if expression:sub(i,i) == "Q" then
						level = level + 1
					elseif expression:sub(i,i) == "Y" then
						level = level - 1
					end
					if level == 0 then
						found = true
						position = i
						break
					end
				end
				if not found then
					error("Assignment does not have matching Y acid in assignment to "..parsed[location].name)
				end
				parsed[location].body = parse(expression:sub(1,position-1))
				expression = expression:sub(position+2,-1)
			elseif expression:sub(2,5) == "INDV" then
				parsed[location].t = "assignmentTableIndex"
				parsed[location].name = expression:sub(6,expression:find('%*')-1)
				expression = expression:sub(expression:find('%*')+2,-1)
				
				local level = 1
				local found = false
				local position = 0
				for i = 1, expression:len() do
					if expression:sub(i,i) == "Q" then
						level = level + 1
					elseif expression:sub(i,i) == "Y" then
						level = level - 1
					end
					if level == 0 then
						found = true
						position = i
						break
					end
				end
				if not found then
					error("Assignment does not have matching Y acid in assignment to "..parsed[location].name)
				end
				parsed[location].index = parse(expression:sub(1,position))
				expression = expression:sub(position+3,-1)
				local level = 1
				local found = false
				local position = 0
				for i = 1, expression:len() do
					if expression:sub(i,i) == "Q" then
						level = level + 1
					elseif expression:sub(i,i) == "Y" then
						level = level - 1
					end
					if level == 0 then
						found = true
						position = i
						break
					end
				end
				if not found then
					error("Assignment does not have matching Y acid in assignment to "..parsed[location].name)
				end
				parsed[location].body = parse(expression:sub(1,position-1))
				expression = expression:sub(position+2,-1)
			else
				error("Invalid asssignment type: "..expression:sub(2,2).."\n"..expression)
			end
			
		elseif expression:sub(1,1) == "C" then
			parsed[#parsed+1] = {t = "methodCall"}
			local location = #parsed
			
			parsed[location].name = expression:sub(2,expression:find('%*')-1)
			expression = expression:sub(expression:find('%*')+1,-1)
			local level = 1
			local found = false
			local position = 1
			for i = 2, expression:len() do
				if expression:sub(i,i) == "Q" then
					level = level + 1
				elseif expression:sub(i,i) == "Y" then
					level = level - 1
				end
				if level == 0 then
					found = true
					position = i
					break
				end
			end
			if not found then
				error("Incorrect Q/Y Pairing in argument setting for a call to"..parsed[location].name)
			end
			arguments = expression:sub(2,position-1)
			origArgs = arguments
			parsed[location].args={}
			expression = expression:sub(position+2,-1)
			while arguments ~= "" do
				arguments = arguments:sub(2,-1)
				local level = 1
				local found = false
				local position = 1
				for i = 1, arguments:len() do
					if arguments:sub(i,i) == "Q" then
							level = level + 1
					elseif arguments:sub(i,i) == "Y" then
						level = level - 1
					end
					if level == 0 then
						found = true
						position = i
						break
					end
				end
				if not found then
					error("Incorrect Q/Y Pairing in argument for a call to"..parsed[location].name..'\nArgs String:'..origArgs)
				end
				table.insert(parsed[location].args,parse(arguments:sub(1,position)))
				arguments = arguments:sub(position+1,-1) 
			end
		--[[elseif expression:sub(1,2) == "LC" then Just use the normal language
			parsed[#parsed+1] = {t = "methodCallLanguage"}
			location = #parsed
			parsed[location].name = expression:sub(3,expression:find('%*')-1)
			expression = expression:sub(expression:find('%*')+1,-1)
			local level = 1
			local found = false
			local position = 1
			for i = 2, expression:len() do
				if expression:sub(i,i) == "Q" then
					level = level + 1
				elseif expression:sub(i,i) == "Y" then
					level = level - 1
				end
				if level == 0 then
					found = true
					position = i
					break
				end
			end
			if not found then
				error("Incorrect Q/Y Pairing in argument setting for a call to"..parsed[location].name)
			end
			arguments = expression:sub(2,position-1)
			parsed[location].args={}
			expression = expression:sub(position+2,-1)
			while arguments ~= "" do
				arguments = arguments:sub(2,-1)
				local level = 1
				local found = false
				local position = 1
				for i = 1, arguments:len() do
					if arguments:sub(i,i) == "Q" then
							level = level + 1
					elseif arguments:sub(i,i) == "Y" then
						level = level - 1
					end
					if level == 0 then
						found = true
						position = i
						break
					end
				end
				if not found then
					error("Incorrect Q/Y Pairing in argument for a call to"..parsed[location].name..'\nArgs String:'..arguments)
				end
				parsed[location].args[#parsed[location].args+1] = parse(arguments:sub(1,position))
				arguments = arguments:sub(position+1,-1) 
			end]]--
		elseif expression:sub(1,1) == "V" then
			parsed[#parsed+1] = {t = "getVariable"}
			location = #parsed
			
			parsed[location].name = expression:sub(2,expression:find('%*')-1)
			expression = expression:sub(expression:find('%*')+1,-1)
		elseif expression:sub(1,1) == "K" then
			parsed[#parsed+1] = {t = "constant"}
			location = #parsed
			
			constant = expression:sub(2,expression:find("%*")-1)
			parsed[location].value = normalizeConstant(constant)
			expression = expression:sub(expression:find("%*")+1,-1)
		--[[elseif expression:sub(1,2) == "LK" then
			parsed[#parsed+1] = {t = "constantLanguage"}
			location = #parsed
			parsed[location].name = expression:sub(3,expression:find('%*')-1)
			expression = expression:sub(expression:find('%*')+1,-1)]]--Just use VPI
		elseif expression:sub(1,2) == "FK" then
			parsed[#parsed+1] = {t = "constant"}
			location = #parsed
			
			constant = expression:sub(2,expression:find("%*")-1)
			parsed[location].value = normalizeFloatingConstant(constant)
			expression = expression:sub(expression:find("%*")+1,-1)
		elseif expression:sub(1,6) == "NPACKV" then
			parsed[#parsed+1] = {t = "unpack"}
			location = #parsed
			
			expression = expression:sub(7,-1)
			parsed[location].table = expression:sub(1,expression:find('%*')-1)
			local toVars={}
			expression = expression:sub(expression:find("%*")+2,-1)
			local level = 1
			local found = false
			local position = 0
			for i = 1, expression:len() do
				if expression:sub(i,i) == "Q" then
					level = level + 1
				elseif expression:sub(i,i) == "Y" then
					level = level - 1
				end
				if level == 0 then
					found = true
					position = i
					break
				end
			end
			if not found then
				error("Unpack of "..parsed[location].table.." does not end")
			end
			toVarString = expression:sub(1,position-1)
			expression = expression:sub(position+2,-1)
			while toVarString ~= "" do
				toVarString = toVarString:sub(2,-1)
				var = toVarString:sub(1,toVarString:find("%*")-1)
				table.insert(toVars,var)
				toVarString = toVarString:sub(toVarString:find("%*"+1),-1)
			end
			parsed[location].toVars = toVars
		elseif expression:sub(1,1) == "R" then
			parsed[#parsed+1] = {t = "return"}
			location = #parsed
			
			expression = expression:sub(3,-1)
			local level = 1
			local found = false
			local position = 0
			for i = 1, expression:len() do
				if expression:sub(i,i) == "Q" then
					level = level + 1
				elseif expression:sub(i,i) == "Y" then
					level = level - 1
				end
				if level == 0 then
					found = true
					position = i
					break
				end
			end
			if not found then
				error("Return does not end")
			end
			parsed[location].body = parse(expression:sub(1,position))
			expression = expression:sub(position+2,-1)
		elseif expression:sub(1,2) == "IF" then
			parsed[#parsed+1] = {t = "if"}
			location = #parsed
			
			expression = expression:sub(4,-1)
			local level = 1
			local found = false
			local position = 0
			for i = 1, expression:len() do
				if expression:sub(i,i) == "Q" then
					level = level + 1
				elseif expression:sub(i,i) == "Y" then
					level = level - 1
				end
				if level == 0 then
					found = true
					position = i
					break
				end
			end
			if not found then
				error("If condition does not end")
			end
			parsed[location].condition = parse(expression:sub(1,position))
			expression = expression:sub(position+3,-1)
			local level = 1
			local found = false
			local position = 0
			for i = 1, expression:len() do
				if expression:sub(i,i) == "Q" then
					level = level + 1
				elseif expression:sub(i,i) == "Y" then
					level = level - 1
				end
				if level == 0 then
					found = true
					position = i
					break
				end
			end
			if not found then
				error("If body does not end")
			end
			parsed[#parsed].body = parse(expression:sub(1,position))
			expression = expression:sub(position+2,-1)
			if expression:sub(1,4) == "ELSE" then
				expression = expression:sub(6,-1)
				local level = 1
				local found = false
				local position = 0
				for i = 1, expression:len() do
					if expression:sub(i,i) == "Q" then
						level = level + 1
					elseif expression:sub(i,i) == "Y" then
						level = level - 1
					end
					if level == 0 then
						found = true
						position = i
						break
					end
				end
				if not found then
					error("Else body does not end")
				end
				parsed[#parsed].elsebody = parse(expression:sub(1,position))
				expression = expression:sub(position+3,-1)
			else
				parsed[#parsed].elsebody = {}
			end
		elseif expression:sub(1,5) == "WHILE" then
			parsed[#parsed+1] = {t = "while"}
			location = #parsed
			
			expression = expression:sub(7,-1)
			local level = 1
			local found = false
			local position = 0
			for i = 1, expression:len() do
				if expression:sub(i,i) == "Q" then
					level = level + 1
				elseif expression:sub(i,i) == "Y" then
					level = level - 1
				end
				if level == 0 then
					found = true
					position = i
					break
				end
			end
			if not found then
				error("While condition does not end")
			end

			parsed[location].condition = parse(expression:sub(1,position))
			expression = expression:sub(position+3,-1)
			local level = 1
			local found = false
			local position = 0
			for i = 1, expression:len() do
				if expression:sub(i,i) == "Q" then
					level = level + 1
				elseif expression:sub(i,i) == "Y" then
					level = level - 1
				end
				if level == 0 then
					found = true
					position = i
					break
				end
			end
			if not found then
				error("While body does not end")
			end
			parsed[#parsed].body = parse(expression:sub(1,position))
			expression = expression:sub(position+2,-1)
		elseif expression:sub(1,1) == "Q" then
			expression = expression:sub(2,-1)
		elseif expression:sub(1,3) == "PRK" then
			expression = expression:sub(4,-1)
			parsed[#parsed+1] = {t="break"}
		else
			error("Unexpected Acid: "..expression:sub(1,1).."\nNext 10 characters: "..expression:sub(2,11))
		end
	end
	return parsed
end
return function(program)
	program=compressProgram(program)
	if program:sub(1,1) ~= "M" or program:sub(-1,-1) ~="*" then
		error("Invalid Program")
	end
	parsed=parse(program)
	return parsed
end, compressProgram