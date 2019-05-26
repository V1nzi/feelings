-- stolen from https://gist.github.com/haggen/2fd643ea9a261fea2094

Hash = {}

local charset = {}  do -- [0-9a-zA-Z]
    for c = 48, 57  do table.insert(charset, string.char(c)) end
    for c = 65, 90  do table.insert(charset, string.char(c)) end
    for c = 97, 122 do table.insert(charset, string.char(c)) end
end

function Hash:random(length)
    if not length or length <= 0 then return '' end
    math.randomseed(os.clock() ^ 5)
    return self:random(length - 1) .. charset[math.random(1, #charset)]
end