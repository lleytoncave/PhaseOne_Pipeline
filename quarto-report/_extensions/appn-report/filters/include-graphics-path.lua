function Meta(meta)
  -- Ensure the assetpath exists in the metadata
  if not meta.assetpath then
    local dir = os.getenv("QUARTO_PROJECT_DIR")
    if dir then
      local styleFilePath = dir:gsub("\\", "/") .. "/_extensions/appn-report/assets"
      meta.assetpath = pandoc.MetaString(styleFilePath)
    else
      -- Fallback if QUARTO_PROJECT_DIR is not available
      meta.assetpath = pandoc.MetaString("_extensions/appn-report/assets")
    end
  end
  return meta
end