local kClasses = pandoc.List({'singlecol', 'doublecol'})

local function printList(list) 
  local result = ''
  local sep = ''
  for i,v in ipairs(list) do
    result = result .. sep .. v
    sep = ', '
  end
  return result
end

return {
	{
    Meta = function(meta)
      if quarto.doc.isFormat("pdf") then
        -- read the journal settings
        local documentclass = meta['documentclass']
    		if documentclass ~= nil then
              documentclass = pandoc.utils.stringify(documentclass)
              if kClasses:includes(documentclass) then
                quarto.doc.addFormatResource(documentclass .. '.cls')
              else
                error("Incorrect document class: " .. documentclass .. "\nPlease use one of " .. printList(kClasses))
              end
            end
        end
        return meta
    end
	}
}
