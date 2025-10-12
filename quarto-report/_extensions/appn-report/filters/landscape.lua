-- Author: [Javier A. Fernandez](https://github.com/jafernandez01)

local ooxml = function (s)
  return pandoc.RawBlock('openxml', s)
end

-- Define the portrait section break with header and footer references
local end_portrait_section = ooxml [[
<w:p>
  <w:pPr>
    <w:sectPr>
      <w:headerReference w:type="first" r:id="rId10" />
      <w:headerReference w:type="default" r:id="rId9" />
      <w:footerReference w:type="first" r:id="rId11"/>
      <w:footerReference w:type="default" r:id="rId12"/>
      <w:titlePg w:val="1" />
    </w:sectPr>
  </w:pPr>
</w:p>
]]

-- Define the landscape section break with header and footer references
local end_landscape_section = ooxml [[
<w:p>
  <w:pPr>
    <w:sectPr>
      <w:pgSz w:h="11906" w:w="16838" w:orient="landscape" />
      <w:headerReference w:type="default" r:id="rId9"/>
      <w:headerReference w:type="first" r:id="rId9"/>
      <w:footerReference w:type="default" r:id="rId12"/>
      <w:footerReference w:type="first" r:id="rId12"/>
      <w:titlePg w:val="0" />
    </w:sectPr>
  </w:pPr>
</w:p>
]]

-- Define the portrait section break for subsequent 'landscape' Divs
local end_portrait_section_subsequent = ooxml [[
<w:p>
  <w:pPr>
    <w:sectPr>
      <w:titlePg w:val="0" />
    </w:sectPr>
  </w:pPr>
</w:p>
]]

-- Track the number of 'landscape' divs
local landscape_counter = 0

-- LateX commands for starting and ending a landscape section
local landscape_start_pdf = pandoc.RawBlock('latex', '\\begin{landscape}')
local landscape_end_pdf = pandoc.RawBlock('latex', '\\end{landscape}')

-- Typst-specific landscape orientation
local landscape_start_typst = pandoc.RawBlock('typst', '#set page(flipped: true)')
local landscape_end_typst = pandoc.RawBlock('typst', '#set page(flipped: false)')

-- Main Div function to apply transformations for DOCX and PDF formats
function Div (div)
  if div.classes:includes 'landscape-section' then
    if FORMAT:match 'docx' then
      -- Increment the counter every time a 'landscape' Div is encountered
      landscape_counter = landscape_counter + 1

      -- Insert portrait section break at the start of the div
      if landscape_counter == 1 then
        -- First 'landscape', add titlePg="1"
        div.content:insert(1, end_portrait_section)
      else
        -- Subsequent 'landscape', do not add titlePg
        div.content:insert(1, end_portrait_section_subsequent)
      end

      -- Insert landscape section break at the end of the div
      div.content:insert(end_landscape_section)
      
    elseif FORMAT:match 'latex' then
      -- PDF-specific landscape orientation using LaTeX
      div.content:insert(1, landscape_start_pdf)
      div.content:insert(landscape_end_pdf)
      
    elseif FORMAT:match 'typst' then
      -- Typst-specific landscape orientation
      div.content:insert(1, landscape_start_typst)
      div.content:insert(landscape_end_typst)
    end
    return div
  end
end













