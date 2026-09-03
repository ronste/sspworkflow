local function is_source_code_div (blk)
  return blk.t == 'Div' and
    #blk.content == 1 and
    blk.content[1].t == 'CodeBlock'
end

local function unite_source_code_divs (divs)
  if not divs[1] then
    return error('Empty list of divs')
  end

  local lines = pandoc.List{}
  for i, div in ipairs(divs) do
    lines:insert(div.content[1].text)
  end
  return pandoc.Div(
    pandoc.CodeBlock(table.concat(lines, '\n')),
    divs[1].attr
  )
end

function Pandoc (doc)
  -- pre-processing: unite successive divs with code blocks into a single block.
  -- This offsets pandoc's behavior if the `styles` option is enabled.
  local old_blocks = doc.blocks
  local new_blocks = pandoc.Blocks{}
  local source_code_divs = pandoc.List{}
  for i, blk in ipairs(old_blocks) do
    if is_source_code_div(blk) then
      source_code_divs:insert(blk)
    elseif next(source_code_divs) then
      -- Combine all consecutive "Source Code" divs and add them to the set of
      -- blocks.
      new_blocks:insert(unite_source_code_divs(source_code_divs))
      new_blocks:insert(blk)
      source_code_divs = pandoc.List{}  -- reset
    else
      new_blocks:insert(blk)
    end
  end
  doc.blocks = new_blocks

  local meta_from_codeblock = function (codeblock)
    local blockdoc = pandoc.read(codeblock.text, 'markdown')
    if next(blockdoc.meta) and not next(blockdoc.blocks) then
      -- could parse the codeblock as a non-empty YAML block
      -- merge the metadata with the main meta
      doc = doc .. blockdoc
      return {}
    else
      return codeblock
    end
  end
  doc.blocks = doc.blocks:walk{CodeBlock = meta_from_codeblock}
  return doc
end
