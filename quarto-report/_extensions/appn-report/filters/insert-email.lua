-- This filter adds the email address of the author below authors block

function Pandoc(doc)
  local email = nil
  
  -- Get the email address from the metadata
  if doc.meta.email then
    email = pandoc.utils.stringify(doc.meta.email)
  end

  -- Add the email address before the date block
  if doc.meta.date then
    doc.meta.date = pandoc.MetaInlines({pandoc.LineBreak(),pandoc.Str("email: " .. email), pandoc.LineBreak(),pandoc.LineBreak(),pandoc.LineBreak(), pandoc.Str(pandoc.utils.stringify(doc.meta.date)) })
  end
  
  return doc
end
