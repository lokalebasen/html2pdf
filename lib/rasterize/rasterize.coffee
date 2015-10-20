page = require('webpage').create()
system = require('system')
address = undefined
output = undefined
size = undefined
if system.args.length < 3 or system.args.length > 7
  console.log 'Usage: rasterize.js URL filename paperwidth*paperheight|paperformat portrait|landscape margin zoomfactor'
  console.log '  paperwidth*paperheight|paperformat examples: "5in*7.5in", "10cm*20cm", "A4", "Letter"'
  console.log '  margin examples: "1cm", "2in"'
  phantom.exit 1
else
  address = system.args[1]
  output = system.args[2]
  page.viewportSize =
    width: 595
    height: 842
  #size
  size = system.args[3].split('*')
  page.paperSize = if size.length is 2
    width: size[0]
    height: size[1]
    orientation: system.args[4]
    margin: system.args[5]
  else
    format: system.args[3]
    orientation: system.args[4]
    margin: system.args[5]
  page.zoomFactor = Number(system.args[6])
  statusCode = undefined

  page.onResourceReceived = (resource) ->
    if resource.url == address
      statusCode = resource.status
    return

  page.open address, (status) ->

    setUpHeaderOrFooter = (headerOrFooter) ->
      hasHeaderOrFooter = page.evaluate(((headerOrFooter) ->
        typeof html2pdf[headerOrFooter] == 'object'
      ), headerOrFooter)
      if hasHeaderOrFooter
        height = undefined
        contents = undefined
        typeOfHeight = page.evaluate(((headerOrFooter) ->
          html2pdf[headerOrFooter].height and typeof html2pdf[headerOrFooter].height
        ), headerOrFooter)
        if typeOfHeight == 'string'
          height = page.evaluate(((headerOrFooter) ->
            html2pdf[headerOrFooter].height
          ), headerOrFooter)
        else
          console.error 'html2pdf.' + headerOrFooter + '.height has wrong type: ' + typeOfHeight
          return phantom.exit(100)
        typeOfContent = page.evaluate(((headerOrFooter) ->
          html2pdf[headerOrFooter].contents and typeof html2pdf[headerOrFooter].contents
        ), headerOrFooter)
        if typeOfContent == 'string' or typeOfContent == 'function'
          contents = phantom.callback((pageNum, numPages) ->
            getHtmlWithStyles headerOrFooter, pageNum, numPages
          )
        else
          console.error 'html2pdf.' + headerOrFooter + '.contents has wrong type: ' + typeOfContent
          return phantom.exit(100)
        paperSize[headerOrFooter] =
          height: height
          contents: contents
        return null
      return

    getHtmlWithStyles = (headerOrFooter, pageNumber, totalPages) ->
      page.evaluate ((headerOrFooter, pageNumber, totalPages) ->
        contents = html2pdf[headerOrFooter].contents
        html = if typeof contents == 'string' then contents else html2pdf[headerOrFooter].contents(pageNumber, totalPages)
        html = html.replace(/\{\{pagenumber\}\}/gi, pageNumber).replace(/\{\{totalpages\}\}/gi, totalPages)
        #Style/footer/Header super-container
        superHost = document.createElement('div')
        superHost.innerHTML = html
        # Styles will be placed before this element. First styles, then foorter/header elements
        stylesGoesBefore = superHost.firstChild

        addStyle = (styleStr) ->
          newStyle = document.createElement('style')
          newStyle.setAttribute 'type', 'text/css'
          newStyle.innerHTML = styleStr
          stylesGoesBefore.insertBefore newStyle
          return

        # https://developer.mozilla.org/en-US/docs/Web/API/document.styleSheets
        # https://developer.mozilla.org/en-US/docs/Web/API/StyleSheet.ownerNode
        i = 0
        while i < document.styleSheets.length
          styleSheet = document.styleSheets[i]
          # CSS from style html element
          if styleSheet.ownerNode.nodeName.toLowerCase() == 'style'
            cssStr = styleSheet.ownerNode.innerHTML
            addStyle cssStr
            # CSS from link html element
          else if styleSheet.ownerNode.nodeName.toLowerCase() == 'link'
            xhReq = new XMLHttpRequest
            xhReq.open 'GET', styleSheet.href, false
            xhReq.send null
            serverResponse = xhReq.responseText
            addStyle serverResponse
          i++
        superHost.outerHTML
      ), headerOrFooter, pageNumber, totalPages

    if status != 'success'
      console.error 'Unable to load the address (' + statusCode + '): ' + address, status
      phantom.exit 100
    else
      if page.evaluate((->
          typeof html2pdf == 'object'
        ))
        paperSize = page.paperSize
        setUpHeaderOrFooter 'header'
        setUpHeaderOrFooter 'footer'
        page.paperSize = paperSize
      window.setTimeout (->
        page.render output
        phantom.exit()
        return
      ), 1000
