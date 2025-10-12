-- Filter to apply APPN formatting to DOCX output
-- This filter ensures the report-series uses the correct APPN color

function Pandoc(doc)
  -- Only apply this filter for DOCX output
  if FORMAT ~= "docx" then
    return doc
  end
  
  -- Walk through all elements in the document
  return doc:walk {
    Str = function(str)
      -- If this is part of the report-series, we'll handle it in the header
      return str
    end,
    
    Header = function(header)
      -- Apply APPN color to headers
      if header.level == 1 then
        -- Create a span with APPN color for level 1 headers
        local colored_content = pandoc.Span(header.content, {style="color: #333F48; font-family: Arial, sans-serif;"})
        header.content = {colored_content}
      end
      return header
    end,
    
    -- Handle title block elements
    MetaString = function(meta_str)
      return meta_str
    end
  }
end

-- Function to apply APPN styling to report-series
function apply_appn_style(elem)
  if elem.t == "Str" and elem.text:match("Australian Plant Phenomics Network") then
    return pandoc.Span({elem}, {style="color: #333F48; font-family: Arial, sans-serif; font-weight: bold;"})
  end
  return elem
end
