--a table serializer
local serializer = {}
function serializer:serialize(t,level,drawLines)
  level = level or 0
  drawLines = drawLines or {[0] = true}
  local vLine = '|'--string.char(186)
  local cross = '+'--string.char(204)
  local hLine = '-'--string.char(205)
  local rAngle = '+'--string.char(200)
  local str = ''
  local count = 0
  local len = 0
  local function generateBars()
    for i = 1,level do
      if drawLines[i-1] then
        str = str .. vLine.."   "
      else
        str = str .. "    "
      end
    end
  end
  if level == 0 then
    str = str.."ROOT\n"
  end
  for k,v in pairs(t) do
    len = len+1
  end
  for k,v in pairs(t) do
    count = count + 1
    generateBars()
    str = str .. vLine .. '\n'
    generateBars()
    str = str..(count == len and rAngle or cross)..hLine..hLine..hLine
    if type(k) == 'number' then
      str = str.."["..k.."] => "
    elseif type(k) == 'string' then
      str = str..k.." => "
    else
      error("Incorrect key type: "..type(k))
    end
    if type(v) == 'table' then
      str = str..tostring(v)..'\n'
      if count==len then
        drawLines[level] = false
      else
        drawLines[level] = true
      end
      str = str..self:serialize(v,level+1,drawLines)
    else
      str = str..tostring(v)..'\n'
    end
  end
  return str
end
function serializer:html(t,level)
  level = level or 0
  local str = ''
  local count = 0
  local len = 0
  local str = ""
  if level == 0 then
    str = [[<details>
    <summary>table</summary>
    <div style="margin-left:3px">
    ]]
  end
  for k,v in pairs(t) do
    len = len+1
  end
  for k,v in pairs(t) do
    if type(v) == 'table' then
      str = str.."<details>\n<summary>"
      str = str..tostring(k)..'</summary><div style="margin-left:'..((level + 2)*3)..'px">\n'
      str = str..self:html(v,level+1)..'</div></details>\n'
    else
      str = str..(type(k) == 'number' and '[' or '')..tostring(k)..(type(k) == 'number' and ']: ' or ': ') ..tostring(v)..'<br/>\n'
    end
  end
  if level == 0 then
    str = str.."</div></details>"
  end
  return str
end
return serializer