--- template-friendly-metadata.lua - easy-access data structures
--
-- Copyright: © 2026 Albert Krewinkel <albert.krewinkel@fu-berlin.de>
-- License: MIT

local List      = require 'pandoc.List'
local utils     = require 'pandoc.utils'

local ptype     = utils.type
local stringify = utils.stringify

local function ensure_string (value)
  return ptype(value) == 'string'
    and value
    or stringify(value)
end

--- Create a deep copy of a table.
local function copy_table (tbl, depth)
  if type(tbl) == 'table' then
    local copy = {}
    -- Iterate 'raw' pairs, i.e., without using metamethods
    for key, value in next, tbl, nil do
      copy[copy_table(key)] = copy_table(value)
    end
    return setmetatable(copy, debug.getmetatable(tbl))
  else -- number, string, boolean, etc
    return tbl
  end
end


local function author_name (author)
  if ptype(author) ~= 'table' or not (author.name or author.literal) then
    error('Author structure has not been normalized!')
  end

  if List{'Inlines', 'string'}:includes(ptype(author.name)) then
    return author.name
  elseif author.name.literal then
    return author.name.literal
  else
    local name = pandoc.Inlines{}
    local name_components = List{
      'given', 'dropping-particle', 'non-dropping-particle',
      'family'
    }
    for name_component in name_components:iter() do
      if ptype(author.name[name_component]) == 'Inlines' then
        name:extend(author.name[name_component])
        name:insert(pandoc.Space())
      end
    end
    -- remove final space
    name:remove()

    return name
  end
end

--- Create a denormalized authors array, with affiliation IDs replaced by the
-- full affiliation record.
local function make_by_authors (authors, affiliations)
  if not authors or not affiliations then
    return nil
  end

  local by_authors = List {}
  local affs = {}
  for aff in affiliations:iter() do
    affs[ensure_string(aff.id)] = aff
  end

  for global_author in authors:iter() do
    -- use a copy of the author so we can modify the record without
    -- changing the global list of authors.
    local author = copy_table(global_author)
    if ptype(author.affiliations) == 'List' then
      author.affiliations = author.affiliations:map(
        function (id) return affs[ensure_string(id)] end
      )
    end
    by_authors:insert(author)
  end

  return by_authors
end

--- Create a denormalized affiliation array, with autho IDs replaced by the
-- full affiliation record.
local function make_by_affiliation (authors, affiliations)
  return List {}
end

--- Create data-structures that are easy to use in templates.
function Pandoc (doc)
  local meta = doc.meta

  local author = meta.author
  local affiliations = meta.affiliations

  meta.author = author and author:map(author_name) or nil
  -- `authors` (plural) becomes the old author
  meta.authors = author

  -- `by-authors` is the denormalized authors array
  meta['by-author'] = make_by_authors(author, affiliations)

  -- `by-affiliation` is the denormalized affiliations array.
  -- FIXME: not supported yet.
  meta['by-affiliation'] = make_by_affiliation(author, affiliations)

  return pandoc.Pandoc(doc.blocks, meta)
end
