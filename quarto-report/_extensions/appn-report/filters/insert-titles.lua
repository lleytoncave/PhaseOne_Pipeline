-- This filter creates structure of cover page for report

function Pandoc(doc)
  -- Check if title and report-series are set in the YAML metadata
  if doc.meta.title and doc.meta["report-series"] then
    
    local title = pandoc.utils.stringify(doc.meta['title'])
    local sectitle_text = pandoc.utils.stringify(doc.meta["report-series"])

    -- Set a new `title` in metadata with report-series
    doc.meta.title = pandoc.MetaString(sectitle_text)
    
    -- Set the original title as subtitle
    -- Set the original subtitle as smaller text
    doc.meta.subtitle = pandoc.MetaInlines({pandoc.Str( title), pandoc.LineBreak(), pandoc.Subscript(pandoc.utils.stringify(doc.meta.subtitle))})
  end

  return doc
end

