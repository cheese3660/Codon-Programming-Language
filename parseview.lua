parser,compress = dofile("CODONPARSER.lua")
program,saveH,saveP,saveC = ...
prg = io.open(program,"r")
prog = prg:read("*a")
prg:close()
out = io.open(saveH,"w")
out:write(dofile("serialize.lua"):html(parser(prog),0))
out:close()
out = io.open(saveP,"w")
out:write(dofile("serialize.lua"):serialize(parser(prog)))
out:close()
out = io.open(saveC,"w")
out:write(compress(prog))
out:close()