--- metadata-table – metadata in normal tables
--
-- Copyright: © 2026 Albert Krewinkel <albert.krewinkel@fu-berlin.de>
-- License: MIT

local List      = require 'pandoc.List'
local utils     = require 'pandoc.utils'

local stringify = utils.stringify
local ptype     = utils.type

local function split (input, sep)
  if sep == nil then
    sep = "%s"
  end
  local fragments = List{}
  for str in string.gmatch(input, "([^"..sep.."]+)") do
    fragments:insert(str)
  end
  return fragments
end

local function add_pair_to_meta (meta, path, value, previous_path)
  if not next(path) or path[1] == '' then
    -- row without a key; ignore and do nothing
    return meta
  end

  local greatest_common_prefix = 0
  for i, elem in ipairs(path) do
    if previous_path and elem == previous_path[i] then
      greatest_common_prefix = greatest_common_prefix + 1
    else
      break
    end
  end

  local function maybe_to_map (index, value)
    local result = value
    local key
    for i = #path, index + 1, -1 do
      result = {[path[i]] = result}
    end
    return result
  end

  local function insert_at_path (map, index, value, force_at_level)
    local subpath = path[index]
    if not map[subpath] then
      map[subpath] = maybe_to_map(index, value)
    else
      -- there's already an entry: try different methods to add this value.
      if ptype(map[subpath]) == 'List' then
        -- Existing value is a list; try to add the value to the last
        -- item; if that fails, then append a new item to the list.
        local list = map[subpath]
        local last = list[#list]
        if ptype(last) == 'table' and not last[subpath] then
          return insert_at_path(last, index + 1, value, force_at_level)
        else
          -- Create a map with the remaining path components if necessary.
          map[subpath]:insert(maybe_to_map(index, value))
          return map
        end
      elseif index == force_at_level then
        -- Previous key was the same as the current key; convert value into a
        -- list that contains the new and old value.
        map[subpath] = List{
          map[subpath],
          maybe_to_map(index, value),
        }
        return map
      elseif index < #path then
        return insert_at_path(map[subpath], index + 1, value, force_at_level)
      else
        -- Force an insert at the given location.
        return insert_at_path(meta, 1, value, greatest_common_prefix)
      end
    end
  end

  return insert_at_path(meta, 1, value, math.maxinteger)
end

--- Convert blocks that contain only a single 'Inlines' value to Inlines.
local function simple_blocks_to_inlines (blks)
  local blk = blks[1]
  if blk and blk.t == 'Para' or blk.t == 'Plain' and not blks[2] then
    return blk.content
  end
  return blks
end

local function table_to_map (tbl)
  local rows = tbl.bodies[1].body
  local map = {}
  local path, lastpath, key, value
  for _, row in ipairs(rows) do
    key = stringify(row.cells[1])
    value = simple_blocks_to_inlines(row.cells[2].content)
    lastpath = path
    path = split(key, '%.')
    add_pair_to_meta(map, path, value, lastpath)
  end
  return map
end

local leave_blocks_to_inlines
leave_blocks_to_inlines = function (x)
  if ptype(x) == 'List' then
    return x:map(function (b) return leave_blocks_to_inlines(b) end)
  elseif ptype(x) == 'table' then
    -- it's a map, recurse on all keys
    for key, value in pairs(x) do
      x[key] = leave_blocks_to_inlines(value)
    end
    return x
  else
    return utils.blocks_to_inlines(x)
  end
end

function Pandoc (doc)
  local is_table = function (b) return b.tag == 'Table' end
  local mdtable, tblidx = doc.blocks:find_if(is_table)
  if mdtable then
    local newmeta = table_to_map(mdtable)
    doc.blocks:remove(tblidx)
    doc = doc .. pandoc.Pandoc({}, newmeta) -- merge metadata
  end

  return doc
end
