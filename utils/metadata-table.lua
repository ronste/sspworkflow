local List      = pandoc.List
local stringify = pandoc.utils.stringify
local ptype     = pandoc.utils.type

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

local function trim (str)
  return type(str) == 'string' and str:gsub('^%s+', ''):gsub('%s+$', '') or str
end

local function table_to_map (tbl)
  local rows = tbl.bodies[1].body
  local map = {}
  for _, row in ipairs(rows) do
    local key = stringify(row.cells[1])
    local value = row.cells[2].content
    if key == '' then -- ignore rows without keys
      goto continue
    elseif map[key] then
      if ptype(map[key]) == List then
        map[key]:insert(value)
      else
        map[key] = List{
          map[key],
          value,
        }
      end
    else
      map[key] = value
    end
    ::continue::
  end
  return map
end

local metavalue_transformations = setmetatable(
  {
    abstract = function (x) -- abstracts can contain multiple paragraphs
      return x
    end,
    author = function (x)
      local authors = List{}
      for i, line in ipairs(x) do
        local fields = split(stringify(line), ';')
        authors:insert {
          ['surname'] = trim(fields[1]),
          ['given-names'] = trim(fields[2]),
          ['affiliation'] = trim(fields[3]),
          ['orcid'] = trim(fields[4]),
          ['email'] = trim(fields[5]),
        }
      end
      return authors
    end,
    keywords = function (x)
      return split(stringify(x), ';'):map(trim)
    end,
  },
  {
    __index = function (t, k)
      return function (x)
        if ptype(x) == 'List' then
          return x
        else
          return pandoc.utils.blocks_to_inlines(x)
        end
      end
    end
  }
)

local function structure_metadata (meta)
  local structured = {}

  local set_value = function (field, rawvalue, lang)
    local value = metavalue_transformations[field](rawvalue)
    if lang then
      structured[lang] = structured[lang] or {}
      structured[lang][field] = value
    else
      structured[field] = value
    end
  end

  for key, value in pairs(meta) do
    if key:sub(1,8) == 'Abstract' then
      set_value('abstract', value, key:match('Abstract(..)$'))
    elseif key:sub(1,8) == 'Keywords' or key == 'Tags' then
      set_value('tags', value, key:match('Keywords(..)$'))
    else
      set_value(key:lower(), value, nil)
    end
  end
  return structured
end

local function hierarchize (map)
  local result = {}
  for key, value in pairs(map) do
    local hierarchies = split(key, '%.')
    local current_map = result
    local current_name = nil
    for i, name in ipairs(hierarchies) do
      if i < #hierarchies then
        -- insert another hierarchy
        current_map[name] = current_map[name] or {}
        if type(current_map[name]) ~= 'table' then
          error("Conflicting metadata info (hierarchy collision) for ", key)
        end
        current_name = name
        current_map = current_map[name]
      else
        -- we reached the bottom, no further hierarchy
        current_map[name] = value
      end
    end
  end
  return result
end

function Pandoc (doc)
  local is_table = function (b) return b.tag == 'Table' end
  local mdtable, tblidx = doc.blocks:find_if(is_table)
  local newmeta = hierarchize(structure_metadata(table_to_map(mdtable)))
  doc.blocks:remove(tblidx)

  return doc .. pandoc.Pandoc({}, newmeta)
end
