function Pandoc(doc)
  -- Check for the YAML argument 'pagebreak-before-h1' in the metadata
  local add_pagebreak = doc.meta["pagebreak-before-h1"]

  -- Ensure the argument is set to 'true' before proceeding
  if add_pagebreak == true then
    -- Create a new list to store the modified blocks
    local new_blocks = {}

    -- Iterate through the blocks in the document
    for _, block in ipairs(doc.blocks) do
      -- Check if the current block is a level-1 heading
      if block.t == "Header" and block.level == 1 then
        -- Create a DOCX-specific page break RawBlock element
        local page_break = pandoc.RawBlock("openxml", "<w:p><w:r><w:br w:type=\"page\"/></w:r></w:p>")

        -- Insert the page break before the level-1 heading
        table.insert(new_blocks, page_break)
      end

      -- Insert the original block (heading or other) into the modified blocks
      table.insert(new_blocks, block)
    end

    -- Replace the document blocks with the new modified blocks
    return pandoc.Pandoc(new_blocks, doc.meta)
  end

  -- If 'pagebreak-before-h1' is not set to true, return the original document
  return doc
end
