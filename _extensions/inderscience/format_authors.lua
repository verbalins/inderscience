local authors
local affiliations
aff_table = {}
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
  quarto.log.debug("Start compare")
  if getTableSize(auth1.affiliations) ~= getTableSize(auth2.affiliations) then
    quarto.log.debug("Not the same size!")
    return false
  end
  quarto.log.debug("Same size!")
  quarto.log.debug("Testing membership between author1 and author2")
  for i,v in pairs(aff_table) do
    if has_value(v.authors, auth1.id) and has_value(v.authors, auth1.id) then
      quarto.log.debug("auth1 and auth2 has same affiliation: " .. v.id)
    elseif has_value(v.authors, auth1.id) then
      quarto.log.debug("Not the same affiliation between aff1 and aff2!")
      return false
    elseif has_value(v.authors, auth2.id) then
      quarto.log.debug("Not the same affiliation between aff1 and aff2!")
      return false
    end
  end
  
  quarto.log.debug("Aff1 and aff2 equal!")
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

function write_affiliation(author, authnr, corr)
  -- Write affiliation here
  local aff_list = {}
  
  local email = false
  for j, affil in pairs(aff_table) do
    local aff = ''
    if has_value(affil.authors, author.id) then
      quarto.log.debug(affil.authors)
      quarto.log.debug("Inserting affiliation for: " .. author.id)
      if author['email'] ~= nil then
        if not email then
          aff = aff .. affil.value .. '\\\\\nEmail: ' .. pandoc.utils.stringify(author['email'])
          email = true
        else
          aff = aff .. affil.value .. '\\\\\nEmail: ' .. pandoc.utils.stringify(author['email'])
        end
      else
        aff = aff .. affil.value
      end
      if corr and j == 1 then
        aff = aff .. '\\\\\n{\\sf{*}}Corresponding author'
      end
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
        
        quarto.log.output(aff_table)
        
        local text = ''
        local corr = false
        if getTableSize(aff_table) == 1 then
          quarto.log.debug("=== One affiliation ===")
          local key, affil = next(aff_table)
          local aff = affil.value
          text = '\\authorA{\\sf{'
          for i, author in pairs(authors) do
            if i == 1 then
              text = text  .. pandoc.utils.stringify(author['name']['literal'])
            else
              text = text .. ', ' .. pandoc.utils.stringify(author['name']['literal'])
            end
          
            if author['attributes'] ~= nil then
              if author['attributes']['corresponding'] ~= nil then
                text = text .. "*"
                corr = true
              end
            end
            if author['email'] ~= nil then
              aff = aff .. '\\\\Email: ' .. pandoc.utils.stringify(author['email'])
            end
          end
          text = text .. '}}\n'

          text = text .. '\\affA{' .. aff
          if corr then
            text = text .. '\\\\{\\sf{*}}Corresponding author'
          end
          text = text .. '}\n'
        elseif getTableSize(aff_table) > 1 then
          quarto.log.debug("=== More than one affiliation ===")
          -- Need to create a list where the different authors are placed 
          -- depending on their affilation. They should be grouped.
          local aff = ''
          local authnr = 1
          local currAuth = auth_tex_table[authnr]
          local cont = true
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
              quarto.log.debug("=== Starting new author: " .. currAuth)
            end
            
            if author['attributes'] ~= nil then
              if author['attributes']['corresponding'] ~= nil then
                currAuth = currAuth .. "*"
                corr = true
              end
            end
            
            if i < getTableSize(authors) then
              if compareAffiliations(author, authors[i+1]) then
                quarto.log.debug(pandoc.utils.stringify(author['name']['literal']) .. " Continue")
                currAuth = currAuth .. ', '
                cont = true
              else
                quarto.log.debug(pandoc.utils.stringify(author['name']['literal']) .. " Not continue")
                cont = false
                aff = aff .. aff_tex_table[authnr]
                aff = aff .. write_affiliation(author, authnr, corr) .. '}\n'
              end
            else
              quarto.log.debug("=== Exiting ===")
              currAuth = currAuth .. '}}\n'
              aff = aff .. aff_tex_table[authnr]
              aff = aff .. write_affiliation(author, authnr, corr) .. '}\n'
              text = text .. currAuth .. aff
            end
          end
        end
        
        quarto.log.debug(text)
        
        quarto.doc.includeText("before-body", text)
        return doc 
        
    end
	}
}
