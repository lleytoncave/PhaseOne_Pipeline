-- Author: [Javier A. Fernandez](https://github.com/jafernandez01)

-- Helper function to generate the appropriate OpenXML raw block
local ooxml = function (s)
  return pandoc.RawBlock('openxml', s)
end

-- Lua filter function to modify the last section of a Word document
function Pandoc(doc)
  -- Check if there is a Div with the class 'landscape'
  local has_landscape = false
  for _, block in ipairs(doc.blocks) do
    if block.t == "Div" and block.classes:includes("landscape-section") then
      has_landscape = true
      break
    end
  end

  -- If no 'landscape' Div is found, return the document unchanged
  if not has_landscape then
    return doc
  end

  -- Define the XML for setting <w:titlePg w:val="0" />
  local titlePg_zero = ooxml [[
    <w:sectPr>
      <w:titlePg w:val="0" />
    </w:sectPr>
  ]]

  -- Iterate over all blocks in the document
  for i = #doc.blocks, 1, -1 do
    local block = doc.blocks[i]

    if block.t == "RawBlock" and block.format == "openxml" then
      -- Check if the block contains the <w:sectPr> tag
      if string.match(block.text, "<w:sectPr>") then
        -- Modify the existing <w:titlePg> tag or add it
        local updated_block = block.text:gsub(
          "<w:titlePg w:val=\"%d\" />",
          "<w:titlePg w:val=\"0\" />"
        )

        -- If no <w:titlePg> exists, add one to the <w:sectPr>
        if updated_block == block.text then
          updated_block = updated_block:gsub(
            "<w:sectPr>",
            "<w:sectPr>\n<w:titlePg w:val=\"0\" />"
          )
        end

        -- Replace the block with the modified content
        doc.blocks[i] = ooxml(updated_block)
        return doc
      end
    end
  end
  

  -- If no <w:sectPr> block was found, add a new section with <w:titlePg>
  table.insert(doc.blocks, titlePg_zero)
  return doc
end
