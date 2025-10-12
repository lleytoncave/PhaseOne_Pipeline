-- add-author-email.lua
-- This filter adds emails to authors in HTML output
-- Supports both single and multiple email addresses

-- Main function to process the document metadata
function Meta(meta)
  -- Only proceed if both author and email exist
  if not meta.author or not meta.email then
    return meta
  end
  
  -- Only modify for HTML output
  if FORMAT:match 'html.*' then
    -- Create CSS class for the email styling
    local css = [[
<style>
.quarto-title-author-email {
  margin-top: 0;
  color: #414042;
}
.quarto-title-author-email a {
  color: #00808b;
  text-decoration: none;
  display: block;
  margin-bottom: 2px;
}
.quarto-title-author-email a:hover {
  text-decoration: underline;
}
</style>
]]
    
    -- Process emails
    local email_html = ""
    -- Debug: Show type and raw value of meta.email
    local email_type = meta.email.t or type(meta.email)
    local email_raw = pandoc.utils.stringify(meta.email)
    local debug_type_html = '<!-- DEBUG: meta.email.t = ' .. tostring(email_type) .. ', meta.email = ' .. email_raw .. ' -->'
    
    -- Check if we have multiple emails (as a list)
    local email_list = {}
    if type(meta.email) == "table" then
      -- Multiple emails in a table (list)
      for i = 1, #meta.email do
        table.insert(email_list, pandoc.utils.stringify(meta.email[i]))
      end
    else
      -- Single email or comma-separated list
      local email_str = pandoc.utils.stringify(meta.email)
      
      -- Check if it's comma-separated
      for e in email_str:gmatch("[^,%s]+") do
        table.insert(email_list, e:match("^%s*(.-)%s*$")) -- Trim whitespace
      end
      
      -- If no commas found, just use the single email
      if #email_list == 0 then
        table.insert(email_list, email_str)
      end
    end
    
    -- After building email_list
    local debug_html = '<!-- DEBUG: email_list = [' .. table.concat(email_list, ', ') .. '] -->'
    
    -- When generating email_html, insert debug_html at the start of the container
    if #email_list > 0 then
      if #email_list == 1 then
        email_html = [[<div class="quarto-title-author-email">]]
        email_html = email_html .. debug_type_html
        email_html = email_html .. debug_html
        email_html = email_html .. string.format(
          [[<a href="mailto:%s">%s</a>]], 
          email_list[1], 
         email_list[1]
        )
        email_html = email_html .. [[</div>]]
     else
       email_html = [[<div class="quarto-title-author-email"><ul style="padding-left: 0; margin: 0;">]]
        email_html = email_html .. debug_type_html
        email_html = email_html .. debug_html
       for _, email in ipairs(email_list) do
          email_html = email_html .. string.format(
            [[<li style="list-style: none;"><a href="mailto:%s">%s</a></li>]], 
            email, 
            email
          )
       end
       email_html = email_html .. [[</ul></div>]]
      end
    end
    
    -- Store the email HTML in metadata
    meta["author-email-html"] = pandoc.MetaBlocks({
      pandoc.RawBlock("html", css),
      pandoc.RawBlock("html", email_html)
    })
  end
  
  return meta
end
