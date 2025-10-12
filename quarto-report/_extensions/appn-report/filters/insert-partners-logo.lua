-- insert-appn-logo.lua
-- This filter inserts the APPN logo after the title block

-- Function to add content after the title block
function add_after_title(meta)
  local html = [[
<style>
.appn-logo-container {
  text-align: center;
  margin-top: 20px;
  margin-bottom: 30px;
  clear: both;
  width: 100%;
}
.appn-logo-img {
  max-width: 400px;
  width: 100%;
  height: auto;
  display: block;
  margin: 0 auto;
}
</style>
<div class="appn-logo-container">
  <img class="appn-logo-img" src="_extensions/appn-report/assets/APPN_logo.png" alt="APPN Logo">
</div>
]]
  return { pandoc.RawBlock('html', html) }
end

-- Main function

function Pandoc(doc)
  local new_blocks = {}
  local added_partners = false
  local meta = doc.meta

  for i, block in ipairs(doc.blocks) do
    if block.t == "Header" and block.level == 1 and not added_partners then
      for _, v in ipairs(add_after_title(meta)) do
        table.insert(new_blocks, v)
      end
      added_partners = true
    end
    table.insert(new_blocks, block)
  end

  if not added_partners then
    for _, v in ipairs(add_after_title(meta)) do
      table.insert(new_blocks, v)
    end
  end

  doc.blocks = new_blocks
  return doc
end
