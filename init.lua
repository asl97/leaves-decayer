leaves_decayer = {}

-- config/settings, copy from moretrees (WTFPL)

local worldpath=minetest.get_worldpath()
local modpath=minetest.get_modpath("leaves_decayer")

if io.open(worldpath.."/leaves_decayer_settings.txt","r") == nil then

	dofile(modpath.."/default_settings.txt")

	io.input(modpath.."/default_settings.txt")
	io.output(worldpath.."/leaves_decayer_settings.txt")

	local size = 2^13      -- good buffer size (8K)
	while true do
		local block = io.read(size)
		if not block then
			io.close()
			break
		end
		io.write(block)
	end
else
	dofile(worldpath.."/leaves_decayer_settings.txt")
end

-- leaves decayer stuff

leaves_decayer.box_formspec =
	"size[8,9]"..
	"list[current_name;src;1,1;1,1;]"..
	"list[current_name;dst;5,1;3,3;]"..
	"list[current_player;main;0,5;8,4;]"

minetest.register_node("leaves_decayer:box", {
	description = "leaves_decayer",
	tiles = {"leaves_decayer_box_top_without_leaves.png", "leaves_decayer_box_bottom.png", "leaves_decayer_box_side.png",
		"leaves_decayer_box_side.png", "leaves_decayer_box_side.png", "leaves_decayer_box_side.png"},
	paramtype2 = "facedir",
	groups = {snappy=3},
	legacy_facedir_simple = true,
	is_ground_content = false,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", leaves_decayer.box_formspec)
		meta:set_string("infotext", "leaves decayer")
		local inv = meta:get_inventory()
		inv:set_size("src", 1)
		inv:set_size("dst", 9)
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		if inv:is_empty("dst") and inv:is_empty("src") then
			return true
		else
			return false
	end
})

-- for some reason, this show up in the unified_inventory :/
minetest.register_node("leaves_decayer:box_with_leaves", {
	description = "leaves_decayer",
	tiles = {"leaves_decayer_box_top_with_leaves.png",
					"leaves_decayer_box_bottom.png", "leaves_decayer_box_side.png",
					"leaves_decayer_box_side.png", "leaves_decayer_box_side.png",
					"leaves_decayer_box_side.png"},
	paramtype2 = "facedir",
	drop = "leaves_decayer:box",
	groups = {snappy=3},
	legacy_facedir_simple = true,
	is_ground_content = false,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", leaves_decayer.box_formspec)
		meta:set_string("infotext", "leaves decayer")
		local inv = meta:get_inventory()
		inv:set_size("src", 1)
		inv:set_size("dst", 9)
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		if inv:is_empty("dst") and inv:is_empty("src") then
			return true
		else
			return false
		end
	end
})

local function swap_node(pos,name)
	local node = minetest.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	minetest.swap_node(pos,node)
end

-- lots of reading the docs,
-- not quite sure how to do it without ItemStack
-- first time coding in lua

minetest.register_abm({
	nodenames = {"leaves_decayer:box","leaves_decayer:box_with_leaves"},
	interval = leaves_decayer.interval,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local meta = minetest.get_meta(pos)

		local inv = meta:get_inventory()

		local src_stack = inv:get_stack("src", 1)

		if inv:is_empty("src") then
			meta:set_string("infotext","box is empty")
			swap_node(pos,"leaves_decayer:box")
		else
			swap_node(pos,"leaves_decayer:box_with_leaves")
			meta:set_string("infotext","leaves are decaying")
			item = src_stack:get_name()
			if minetest.get_item_group(item, "leafdecay") ~= 0 then
				drops = minetest.get_node_drops(item)
				for _, itemname in ipairs(drops) do
					if inv:room_for_item("dst", ItemStack(itemname)) then
						new_stack = src_stack:take_item(src_stack:get_count() - 1)
						if item ~= itemname then
							inv:add_item("dst", ItemStack(itemname))
							inv:set_stack("src", 1, new_stack)
						elseif leaves_decayer.decay_into_nothing then
							inv:set_stack("src", 1, new_stack)
						end
					end
				end
			end
		end
	end
})

-- recipe for crafting the box

minetest.register_craft({
	output = 'leaves_decayer:box',
	recipe = {
		{'group:wood', '',             'group:wood'},
		{'group:wood', 'group:leaves', 'group:wood'},
		{'group:wood', 'group:wood',   'group:wood'},
	}
})

