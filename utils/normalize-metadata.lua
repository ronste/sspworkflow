--- normalize-metadata.lua - bring metadata into a standard structure
--
-- Copyright: © 2026 Albert Krewinkel <albert.krewinkel@fu-berlin.de>
-- License: MIT

local List      = require 'pandoc.List'
local log       = require 'pandoc.log'
local structure = require 'pandoc.structure'
local text      = require 'pandoc.text'
local utils     = require 'pandoc.utils'

local ptype     = utils.type
local stringify = utils.stringify
local unique_identifier = structure.unique_identifier

--- Name of this filter; used for configuration.
local filter_name = 'normalize-metadata'

--- Trim leading and trailing whitespace.
local function trim (str)
  return type(str) == 'string' and str:gsub('^%s+', ''):gsub('%s+$', '') or str
end

--- Split a @sep@-delimited string into a List.
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

--- Break Inlines into two parts at the first occurence of a separator.
-- Omits the separator from the result.
local function break_inlines(inlns, sep)
  local before = pandoc.Inlines{}
  local after = List{}
  local current = before
  local pattern = '^([^' .. sep .. ']*)' .. sep .. '(.*)$'
  for i, inln in ipairs(inlns) do
    if current == after or inln.t ~= 'Str' then
      current:insert(inln)
    else
      local pre, post = inln.text:match(pattern)
      if not pre or not post then
        before:insert(inln)
      else
        if pre ~= '' then
          before:insert(pandoc.Str(pre))
        end
        if post ~= '' then
          after:insert(pandoc.Str(post))
        end
        current = after
      end
    end
  end
  return before, after
end

local function trim_inlines (inlns, sep)
  local result = inlns:clone()
  local is_whitespace = function (x)
    return List{'Space', 'LineBreak'}:includes(x.t)
  end
  -- trim start
  while result[1] and is_whitespace(result[1]) do
    result:remove(1)
  end
  -- trim end
  while result[#inlns] and is_whitespace(result[#inlns]) do
    result:remove(#inlns)
  end
  return result
end

local function split_inlines(inlns, sep)
  local result = List{}
  local before, after
  repeat
    before, after = break_inlines(inlns, sep)
    result:insert(trim_inlines(before))
    inlns = after
  until not next(after)
  return result
end

--- Split and transform fields based on user configuration.
local function user_defined_fields (meta, config)
  for field, convert_value in pairs(config.fields) do
    if meta[field] then
      meta[field] = convert_value(meta[field])
    end
  end
  return meta
end

--- Set the `lang` attribute, unsets any `language` attribute
--
-- This should avoid confusion.
local function lang (meta)
  meta.lang     = meta.lang or meta.language
  meta.language = nil

  return meta
end

--- Collect values with a language code suffix into a map for each language.
local function lang_suffixes (meta)
  local result = {}
  for key, value in pairs(meta) do
    if type(key) == 'string' then
      local prefix, lang = key:match '^(.*[a-z])([A-Z][A-Z])$'
      if prefix and lang then
        lang = lang:lower()
        result[key] = nil
        result[lang] = result[lang] or {}
        result[lang][prefix] = value
      else
        result[key] = value
      end
    else
      result[key] = value
    end
  end
  return result
end

--- Ensure that all keys are lowercase.
local lowercase
lowercase = function (meta)
  if type(meta) ~= 'table' then
    return meta
  end

  local result = setmetatable({}, getmetatable(meta))
  for key, value in pairs(meta) do
    if type(key) == 'string' then
      local newkey = text.lower(key)
      if newkey ~= key and meta[newkey] then
        log.warn('Overwriting ' .. newkey .. ' with ' .. key .. ' value')
      else
        result[key] = nil
      end

      result[newkey] = lowercase(value)
    else
      result[key] = lowercase(value)
    end
  end

  return result
end

--- The Inlines metatable
local InlinesMT = debug.getmetatable(pandoc.Inlines{})
--- The Blocks metatable
local BlocksMT = debug.getmetatable(pandoc.Blocks{})

local ensure_type
ensure_type = setmetatable(
  {
    Blocks = function (obj, key)
      shift = shift or 0
      local pt = ptype(obj)
      if pt == 'Blocks' then
        return obj
      elseif pt == 'List' or pt == 'table' then
        return setmetatable(obj, BlocksMT)
      elseif pt == 'Inline' then
        return setmetatable({pandoc.Plain{obj}}, BlocksMT)
      elseif pt == 'Inlines' then
        return setmetatable({pandoc.Plain(obj)}, BlocksMT)
      else
        return pandoc.Blocks(obj)
      end
    end,

    Inlines = function (obj)
      local pt = ptype(obj)
      if pt == 'Inlines' then
        return obj
      elseif pt == 'List' or pt == 'table' then
        return setmetatable(obj, InlinesMT)
      elseif pt == 'Blocks' then
        return utils.blocks_to_inlines(obj)
      else
        return pandoc.Inlines(obj)
      end
    end,

    -- Note that this returns a second-order function, i.e., a function that needs
    -- the item type as input and returns the final converter function.
    List = function (itemtype)
      return function (obj)
        local ty = ptype(obj)
        if ty == 'List' then
          return obj:map(ensure_type[itemtype])
        elseif itemtype == 'Inlines' and ty == 'Inlines' then
          -- A list of inlines is expected, but an Inlines value is given.
          -- Try to split it, using semicolons as separators.
          return split_inlines(obj, '%;')
        else
          -- Returns a singleton list as fallback
          return List { ensure_type[itemtype](obj) }
        end
      end
    end,

    string = function (obj)
      if type(obj) == 'string' then
        return obj
      elseif List{'Inlines', 'Inline', 'Blocks', 'Block'}:includes(ptype(obj)) then
        return utils.stringify(obj)
      end
      return tostring(obj)
    end,
  },
  {
    __index = function (t, key)
      if type(key) == 'function' then
        return key
      else
        return rawget(t, key)
      end
    end,
  }
)

--- Set of normalizers for metadata fields.
normalizers = {
  keywords = ensure_type['List']('Inlines'),
  title    = ensure_type['Inlines'],
}

--- Normalize the types of all known elements.
local function normalize_types (meta)
  for key, normalizer in pairs(normalizers) do
    if meta[key] ~= nil then
      meta[key] = normalizer(meta[key])
    end
  end
  return meta
end

--- Create subfields from user supplied configurations for a field.
local function user_fields_to_converter (field_conf)
  local fields = {}
  if ptype(field_conf) ~= 'table' then
    return fields
  end

  for field, subfields in pairs(field_conf) do
    local subfield_names = split(stringify(subfields), '%;')
    local subfield_creator = function (value)
      local inlines_value = ensure_type['Inlines'](value)
      local subfield_values = split_inlines(inlines_value, '%;')
      local result = {}
      for i, subfield in ipairs(subfield_names) do
        result[subfield] = subfield_values[i]
      end
      return result
    end
    fields[field] = function (value)
      if ptype(value) == 'List' then
        return value:map(subfield_creator)
      else
        return subfield_creator(value)
      end
    end
  end
  return fields
end

--- Access a table field by name; fall back to the given aliases if necessary.
local function get_field_or_alias(t, key, aliases)
  if t[key] or not aliases then
    return t[key], key
  end

  for alias in aliases:iter() do
    if t[alias] then
      return t[alias], alias
    end
  end

  -- Neither key nor any alias key is set, return nothing
  return nil, key
end

--- Return a normalized record using the given normalizers and aliases tables
local function normalized_record (value, field_normalizers, field_aliases)
  local result = {}

  -- Add and normalize all supported author fields
  local aliases, fieldval
  for field, normalizer in pairs(field_normalizers) do
    aliases = field_aliases and field_aliases[field] or nil
    fieldval = get_field_or_alias(value, field, aliases)
    result[field] = fieldval and normalizer(fieldval) or nil
  end

  return result
end

--             _   _
--  __ _ _   _| |_| |__   ___  _ __
-- / _` | | | | __| '_ \ / _ \| '__|
--| (_| | |_| | |_| | | | (_) | |
-- \__,_|\__,_|\__|_| |_|\___/|_|
--

-- ORCID
local orcid_pattern =
  '^(%d%d%d%d)%-?(%d%d%d%d)%-?(%d%d%d%d)%-?(%d%d%d)([%dXx])$'

local function normalize_orcid (orcid)
  if not orcid then
    return nil
  end
  orcid_str = stringify(orcid)

  -- Strictly speaking, an ORCID is an URL, but we allow users to
  -- omit schema and host. Keep the digits.
  orcid_str = orcid_str:gsub('^https://orcid%.org/', '')
  local b1, b2, b3, b4, check = orcid_str:match(orcid_pattern)
  if not (b1 and b2 and b3 and b4 and check) then
    return nil
  end

  local digits = b1 .. b2 .. b3 .. b4

  local total = 0
  for digit in digits:gmatch '.' do
    total = (total + tonumber(digit)) * 2
  end

  local remainder = total % 11
  local result = (12 - remainder) % 11

  local is_valid = result == 10
    and check:upper() == "X"
    or tonumber(check) == result

  return is_valid
    and string.format('%s-%s-%s-%s%s', b1, b2, b3, b4, check)
    or nil
end

-- Normalize the ORCID of each author, if given.
local function author_orcid (meta)
  local authors = meta.author
  if authors == nil then
    -- do nothing if there are no authors.
    return meta
  elseif ptype(authors) ~= 'List' then
    warn("`author` field is not a List; skipping 'author_orcid'")
    return meta
  end
  for author in authors:iter() do
    if author.orcid then
      local normalized_orcid = normalize_orcid(author.orcid)
      author.orcid = normalized_orcid
        or warn("ignoring invalid orcid: " .. stringify(author.orcid))
    end
  end
  return meta
end

local bibtex_template = [[
@misc{x,
  author = {%s}
}
]]

--- Normalizes personal names.
local function to_name_components (name)
  local bibtex = bibtex_template:format(stringify(name))
  local namerec = pandoc.read(bibtex, 'bibtex').meta.references[1].author[1]
  if type(namerec) ~= 'table' then
    return {name = name}
  else
    -- all name components should be Inlines
    for key, value in pairs(namerec) do
      namerec[key] = ensure_type['Inlines'](value)
    end
    return namerec
  end
end

--- Supported name components
local name_components = {
  ['given'] = ensure_type['Inlines'],
  ['dropping-particle'] = ensure_type['Inlines'],
  ['non-dropping-particle'] = ensure_type['Inlines'],
  ['family'] = ensure_type['Inlines'],
  ['literal'] = ensure_type['Inlines'],
}

local name_field_aliases = {
  ['given'] =
    List{'given-names', 'given-name', 'firstname', 'first', 'forename'},
  ['family'] = List{'surname', 'lastname', 'last'},
}

--- Bring the author name into a normalized structure
local function normalize_name_record (value)
  if ptype(value) ~= 'table' then
    -- Try the best to convert a value to a name record
    return to_name_components(value)
  end

  local name = normalized_record(value, name_components, name_field_aliases)

  -- If a middle name is given, then add it to given names
  if ptype(value.middle) == 'Inlines' and next(value.middle) then
    if name.given then
      name.given:insert(pandoc.Space())
    else
      name.given = pandoc.Inlines{}
    end
    name.given:extend(value.middle)
  end
  return name
end

local author_fields = {
  ['name'] = normalize_name_record,
  ['url'] = ensure_type['string'],
  ['email'] = ensure_type['string'],
  ['phone'] = ensure_type['string'],
  ['fax'] = ensure_type['string'],
  ['degrees'] = ensure_type['List']('Inlines'),
  ['orcid'] = normalize_orcid,
  ['note'] = ensure_type['Inlines'],
  ['acknowledgements'] = ensure_type['Blocks'],
  ['attributes'] = function (x) return x end, -- FIXME!
  ['roles'] = function (x) return x end, -- FIXME!
  ['metadata'] =  function (x) return x end, -- anything goes
  ['affiliations'] = function (x) return x end, -- FIXME!
}

local author_field_aliases = {
  ['email'] = List{'e-mail'},
  ['acknowledgements'] = List{'thanks'},
  ['affiliations'] = List{'affiliation'},
}

local function to_author_record (value)
  if ptype(value) ~= 'table' then
    value = {name = value}
  elseif not value.name then
    -- the name is not a separate table, but was probably folded
    -- into the author record; we'll get all the info we need by using
    -- the full author record as the `name` table.
    value.name = value
  end

  return normalized_record(value, author_fields, author_field_aliases)
end

--- Ensure that `author` is a list of author records.
local function author_records (meta)
  local author = meta.author

  local ty = ptype(author)
  if author == nil then
    -- Do nothing if there's no author
  elseif ty == 'List' then
    meta.author = author:map(to_author_record)
  else
    meta.author = List{to_author_record(author)}
  end

  return meta
end

--         __  __ _ _ _       _   _
--   __ _ / _|/ _(_) (_) __ _| |_(_) ___  _ __  ___
--  / _` | |_| |_| | | |/ _` | __| |/ _ \| '_ \/ __|
-- | (_| |  _|  _| | | | (_| | |_| | (_) | | | \__ \
--  \__,_|_| |_| |_|_|_|\__,_|\__|_|\___/|_| |_|___/
--

local affiliation_fields = {
  ['id'] = ensure_type['string'],
  ['name'] = ensure_type['Inlines'],
  ['department'] = ensure_type['Inlines'],
  ['group'] = ensure_type['Inlines'],
  ['address'] = ensure_type['Inlines'],
  ['city'] = ensure_type['Inlines'],
  ['region'] = ensure_type['Inlines'],
  ['country'] = ensure_type['Inlines'],
  ['postal-code'] = ensure_type['Inlines'],
  ['url'] = ensure_type['string'],
  ['ror'] = ensure_type['string'], -- Research Organization Registry identifier
}

local affiliation_field_aliases = {
  ['postal-code'] = List{'zip', 'zip-code'},
}

--- Known affiliations, indexed by ID.
local affs_by_ids = {}

local function ensure_affiliation_id (aff)
  if aff.id then
    -- already has an ID; convert to string and note that it's been used.
    aff.id = stringify(aff.id)
    affs_by_ids[aff.id] = aff
    return aff
  end

  aff.id = unique_identifier(aff.name or '', affs_by_ids)
  affs_by_ids[aff.id] = aff
  return aff
end

local function to_affiliation_record (value)
  if ptype(value) ~= 'table' then
    value = {name = value}
  end

  return normalized_record(
    value,
    affiliation_fields,
    affiliation_field_aliases
  )
end

-- collect used IDs, then add new IDs to all records without one.
local function ensure_affiliation_ids (affs)
  return affs
    :map(
      function (aff)
        if aff.id then
          affs_by_ids[aff.id] = aff
        end
        return aff
      end)
    :map(ensure_affiliation_id)
end

local function affiliation_records (meta)
  local affiliations = meta.affiliations
    and ensure_type['List'](to_affiliation_record)(meta.affiliations)
    or List{}

  -- "affiliation" is an alias for "affiliations"
  if meta.affiliation then
    affiliations:extend(
      ensure_type['List'](to_affiliation_record)(meta.affiliation))
    meta.affiliation = nil
  end

  meta.affiliations = next(affiliations)
    and ensure_affiliation_ids(affiliations)
    or nil
  return meta
end

local function affiliation_matches (aff1, aff2)
  if aff1.id == aff2.id then
    return true
  end

  for field in pairs(affiliation_fields) do
    if aff1[field] and aff2[field] and aff1[field] ~= aff2[field] then
      return false
    end
  end

  return true
end


local function matching_affiliation (value, affiliations)
  local match_by_id_or_name = function (id_or_name, ty)
    ty = ty or ptype(ty)
    local id = ty == 'string' and value or stringify(value)
    if affs_by_ids[id] then
      return affs_by_ids[id], id
    end

    -- not a known ID, let's try matching by name
    local name = ty == Inlines and value or pandoc.Inlines(value)
    for known_id, known_aff in pairs(affs_by_ids) do
      if known_aff.name == name then
        -- names are matching, let's assume that this is the right one
        return known_aff, known_id
      end
    end

    -- neither id nor name match. Maybe it's an index number.
    local idx = tonumber(id)
    if idx and 0 < idx and idx <= #affiliations then
      return affiliations[idx], affiliations[idx].id
    end

    -- found nothing
    return nil, nil
  end

  local ty = ptype(value)
  if ty == 'string' or ty == 'Inlines' then
    return match_by_id_or_name(value, ty)
  end

  return nil, nil
end

--- Normalize author affiliations.
--
-- This moves affiliation records that are nested below authors to the
-- top-level `affiliations` list and establishes the correct link.
local function author_affiliations (meta)
  -- Create a list of all known affiliations. This will likely contain
  -- duplicates when the inline authors are added.
  local affiliations = meta.affiliations
    and meta.affiliations:clone()
    or List{}

  -- merge inline affiliations, i.e., those defined below an author record,
  -- into the top-level affiliations list.
  local inline_affs = List{}
  for author in (meta.author or List{}):iter() do
    if author.affiliations then
      author.affiliations =
        ensure_type['List'](function (x) return x end)(author.affiliations)
      local global_aff, aff_id
      for i, aff in ipairs(author.affiliations) do
        global_aff, aff_id = matching_affiliation(aff, affiliations)
        if not aff_id then
          local new_record = ensure_affiliation_id(to_affiliation_record(aff))
          aff_id = new_record.id
          affiliations:insert(new_record)
        end
        author.affiliations[i] = aff_id
      end
    end
  end

  -- unset global affiliations field if there are no affiliations
  meta.affiliations = next(affiliations) and affiliations or nil
  return meta
end


--                  __ _
--  ___ ___  _ __  / _(_) __ _
-- / __/ _ \| '_ \| |_| |/ _` |
--| (_| (_) | | | |  _| | (_| |
-- \___\___/|_| |_|_| |_|\__, |
--                       |___/

--- Available transformations / normalization routines
local transformations = {
  affiliation_records = affiliation_records,
  author_affiliations = author_affiliations,
  author_orcid = author_orcid,
  author_records = author_records,
  lang = lang,
  lang_suffixes = lang_suffixes,
  lowercase = lowercase,
  normalize_types = normalize_types,
  user_defined_fields = user_defined_fields,
}

--- Default filter config
local default_config = {
  fields = {},
  --- Active normalizations
  normalizations = List {
    'user_defined_fields',
    'lang_suffixes',
    'lowercase',
    'lang',
    'affiliation_records',
    'author_records',
    'author_orcid',
    'author_affiliations',
    'normalize_types',
  },
}

--- Get the config
local function get_config (meta)
  local conf = meta[filter_name]
  if ptype(conf) ~= 'table' then
    return default_config
  end

  local config = default_config

  -- Set the record converters
  config.fields = user_fields_to_converter(conf.fields)
  local normalizations = conf.normalizations or conf.normalisations or
    conf.normalization or conf.normalisation
  config.normalizations = normalizations
    and ensure_type['List']('string')(normalizations)
    or config.normalizations
  return config
end

--- Run all selected normalizations on the metadata.
function Pandoc (doc)
  doc = doc:clone()  -- prevent any typing issues
  local normalized = doc.meta

  local config = get_config(normalized)
  -- remove config from metadata
  normalized[filter_name] = nil

  for tf in config.normalizations:iter() do
    normalized = transformations[tf](normalized, config)
  end

  return pandoc.Pandoc(doc.blocks, normalized)
end
