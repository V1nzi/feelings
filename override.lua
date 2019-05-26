--[[
	Stolen from https://github.com/taikedz-mt/entity_override, because
	- the mod is not findable over the official search menu
	- more importantly, it didn't work, because the self parameter in the functions was missing. I have no idea of lua, but when dumping the first parameter of a function of the override table, it just returns a table containing all the functions of the override table + I searched the internet, which is always right (obsiously).

	Also I removed the cloning functionality, because that's not needed for my purpose of introducing feelings into the minetest world
]]

-- lua entities overrider

override = {}

local sethas = function(needle, haystack)
	for _,i in pairs(haystack) do
		if i == needle then return true end
	end
	return false
end

local concat_tables = function(table1, table2)
	local newtable = {}
	if table1 ~= nil then for _,v in ipairs(table1) do newtable[#newtable+1] = v end end
	if table2 ~= nil then for _,v in ipairs(table2) do newtable[#newtable+1] = v end end
	return newtable
end

local mobs_override = function(_self, mobname, def, check)
	local themob = minetest.registered_entities[mobname]
    if themob == nil then return end

	if type(check) == "function" then
		if not check(themob) then return end
	end

	for property,definition in pairs(def) do
		-- minetest.debug("Redefine "..property)
		if type(definition) == "string"
		or type(definition) == "number"
		or type(definition) == "function"
		or type(definition) == "boolean"
		then
			--minetest.debug(" ... simply as "..dump(definition) )
			themob[property] = definition

		elseif type(definition) == "table" then
			--minetest.debug(" ... with table ")
			if type(definition.check) == "function" then
				if definition.check(themob[property]) then themob[property] = definition.value end

			elseif definition.value then -- straight definition
				--minetest.debug(" ... as tablevalue "..dump(definition) )
				if definition.tableorder == "append" then
					themob[property] = concat_tables(themob[property],definition.value)
				elseif definition.tableorder == "prepend" then
					themob[property] = concat_tables(definition.value,themob[property])
				else
					themob[property] = definition.value
				end

			elseif sethas(definition.fchain_type, {"after","before"}) and type(definition.fchain_func) == "function" then
				--minetest.debug(" ... as a function")
				local extantf = themob[property]
				if type(extantf) == "function" then
					if definition.fchain_type == "after" then
						themob[property] = function(...)
							extantf( ... )
							definition.fchain_func( ... )
						end
					elseif definition.fchain_type == "before" then
						themob[property] = function(...)
							if definition.fchain_func( ... ) == true then -- check for the actual boolean value
								extantf( ... )
							end
						end
					end

				else
					minetest.debug("Expected existing function in "..property.." for "..mobname.." but got a "..type(extantf))
				end
			else
				minetest.debug("Invalid substitution definition of "..property.." for "..mobname)
			end
		end
	end
	return themob
end

override.rewrite = mobs_override