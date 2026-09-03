local List      = pandoc.List
local stringify = pandoc.utils.stringify

local metakey = {
  ['lang'] = 'Lang',
}

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


local metadata = {}

local function table_to_map (tbl)
  local rows = tbl.bodies[1].body
  local map = {}
  for _, row in ipairs(rows) do
    local key = stringify(row.cells[1])
    local value = row.cells[2].content
    map[key] = value
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
          lastname = fields[1],
          firstname = fields[2],
          affiliation = fields[3],
          orcid = fields[4],
          email = fields[5],
        }
      end
      return authors
    end,
    keywords = function (x)
      return split(stringify(x), ';')
    end,
  },
  {
    __index = function (t, k)
      return pandoc.utils.blocks_to_inlines
    end
  }
)

local function structure_metadata (meta)
  local main_lang = meta[metakey['lang'] or 'lang'] or 'en'
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
    elseif key:sub(1,8) == 'Keywords' then
      set_value('keywords', value, key:match('Keywords(..)$'))
    else
      set_value(key:lower(), value, nil)
    end
  end
  return structured
end

function Pandoc (doc)
  local is_table = function (b) return b.tag == 'Table' end
  local mdtable, tblidx = doc.blocks:find_if(is_table)
  local newmeta = structure_metadata(table_to_map(mdtable))
  doc.blocks:remove(tblidx)

  return doc .. pandoc.Pandoc({}, newmeta)
end
