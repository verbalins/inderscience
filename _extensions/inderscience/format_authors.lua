local authors
local affiliations
local aff_table = {}
local email_table = {}
local biography = {}
local auth_tex_table = {'\\authorA{\\sf{', '\\authorB{\\sf{', '\\authorC{\\sf{', '\\authorD{\\sf{'}
local aff_tex_table = {'\\affA{', '\\affB{', '\\affC{', '\\affD{'}

function getTableSize(t)
    local count = 0
    for _, __ in pairs(t) do
        count = count + 1
    end
    return count
end

function compareAffiliations(auth1, auth2)
  if getTableSize(auth1.affiliations) ~= getTableSize(auth2.affiliations) then
    return false
  end

  for i,v in pairs(aff_table) do
    if has_value(v.authors, auth1.id) and has_value(v.authors, auth1.id) then
    elseif has_value(v.authors, auth1.id) then
      return false
    elseif has_value(v.authors, auth2.id) then
      return false
    end
  end

  return true
end

function has_value (tab, val)
  for index, value in ipairs(tab) do
    if value == val then
        return true
    end
  end
  return false
end

function write_affiliation(all_authors, corr)
  -- Write affiliation here
  local aff_list = {}
  for j, affil in pairs(aff_table) do
    local aff = ''
    if has_value(affil.authors, all_authors[1].id) then
      aff = aff .. affil.value
    end
    
    if j == 1 then
      for k, v in pairs(all_authors) do -- Write emails on first affiliation
        local author = v
        if author['email'] ~= nil then
          if not has_value(email_table, author.id) then
            aff = aff .. '\\\\\nEmail: ' .. pandoc.utils.stringify(author['email'])
            table.insert(email_table, author.id)
          end
        end
      end
      
      if corr then
        aff = aff .. '\\\\\n{\\sf{*}}Corresponding author'
      end
    end
    
    if aff ~= '' then
      table.insert(aff_list, aff)
    end
  end
  return table.concat(aff_list, '\\\\\n~\\\\\n')
end

return {
	{
    Meta = function(meta)
      authors = meta['by-author']
      affiliations = meta['by-affiliation']
      return meta
    end,
    Pandoc = function(doc)
        if not quarto.doc.isFormat("latex") then
          return doc
        end
        
        -- Create the affiliations table
        for i, aff in pairs(affiliations) do
            local aff_name = ''
            if aff['department'] ~= nil then
              aff_name = aff_name .. pandoc.utils.stringify(aff['department']) .. ',\\\\\n'
            end
            aff_name = aff_name .. pandoc.utils.stringify(aff['name']) .. ',\\\\\n'
            
            local address = {}
            if aff['address'] ~= nil then
              table.insert(address, pandoc.utils.stringify(aff['address']))
            end
            
            if aff['postal-code'] ~= nil then
              table.insert(address, pandoc.utils.stringify(aff['postal-code']))
            end
            
            if aff['city'] ~= nil then
              table.insert(address, pandoc.utils.stringify(aff['city']))
            end
            
            if aff['country'] ~= nil then
              table.insert(address, pandoc.utils.stringify(aff['country']))
            end
            
            local affiliation_authors = {}
            for i, auth in pairs(aff.authors) do
              table.insert(affiliation_authors, auth.id)
            end
            
            table.insert(aff_table, {id = pandoc.utils.stringify(aff['id']), 
              value = aff_name .. table.concat(address, ', '), 
              authors = affiliation_authors})
        end
        
        local text = ''
        local corr = false
        -- Need to create a list where the different authors are placed 
        -- depending on their affilation. They should be grouped.
        local aff = ''
        local authnr = 1
        local currAuth = auth_tex_table[authnr]
        local cont = true
        local all_authors = {}
        for i, author in pairs(authors) do
          corr = false
          if cont then
            currAuth = currAuth .. pandoc.utils.stringify(author['name']['literal'])
          else
            currAuth = currAuth .. '}}\n'
            text = text .. currAuth
            authnr = authnr + 1
            currAuth = auth_tex_table[authnr]
            currAuth = currAuth  .. pandoc.utils.stringify(author['name']['literal'])
          end
          
          if author['attributes'] ~= nil then
            if author['attributes']['corresponding'] ~= nil then
              currAuth = currAuth .. "*"
              corr = true
            end
          end
          
          -- Biographies
          if author['metadata'] ~= nil then
            if author['metadata']['biography'] ~= nil then
              table.insert(biography, pandoc.utils.stringify(author['metadata']['biography']))
            end
          end
          
          table.insert(all_authors, author)
          
          if i < getTableSize(authors) then
            if compareAffiliations(author, authors[i+1]) then
              currAuth = currAuth .. ', '
              cont = true
            else
              cont = false
              aff = aff .. aff_tex_table[authnr]
              aff = aff .. write_affiliation(all_authors, corr) .. '}\n'
              all_authors = {}
            end
          else
            currAuth = currAuth .. '}}\n' -- Finish the last author
            aff = aff .. aff_tex_table[authnr]
            aff = aff .. write_affiliation(all_authors, corr) .. '}\n'
            text = text .. currAuth .. aff
            all_authors = {}
          end
        end
        
        if getTableSize(biography) > 0 then
          text = text .. '\n\\begin{bio}\n'
          for i,v in ipairs(biography) do
            if i == 1 then
              text = text .. v .. '\\vs{8}\n\n'
            elseif i == getTableSize(biography) then
              text = text .. '\\noindent '.. v .. '\n'
            else
              text = text .. '\\noindent '.. v .. '\\vs{8}\n\n'
            end
             
          end
          text = text .. '\\end{bio}\n'
        end
        
        quarto.doc.includeText("before-body", text)
        return doc
        
    end
	}
}
