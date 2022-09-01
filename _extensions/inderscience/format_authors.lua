local authors
local affiliations

return {
	{
    Meta = function(meta)
      authors = meta['by-author']
      affiliations = meta['affiliations']
      --logging.temp('meta', authors)
      return meta
    end,
    Pandoc = function(doc)
        if not quarto.doc.isFormat("latex") then
          return doc
        end
        local text
        for i, author in pairs(authors) do
            print(author['number'])
            if author['number'] == '1' then
                text = '\\authorA{\\sf{'
            elseif pandoc.utils.stringify(author['number']) == '2' then
                text = text .. '\\authorB{\\sf{'
            elseif pandoc.utils.stringify(author['number']) == '3' then
                text = text .. '\\authorC{\\sf{'
            elseif pandoc.utils.stringify(author['number']) == '4' then
                text = text .. '\\authorD{\\sf{'
            end
            text = text .. pandoc.utils.stringify(author['name']['literal']) .. '}}' .. '\n'
        end
        
        quarto.doc.includeText("before-body", text)
        return doc 
    end
	}
}
