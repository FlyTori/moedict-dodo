<- $
score = 0
key = ''
record = ''
items = []
$ \.hidden .hide!

MAX = 10

$ \#quit .click ->
  $ \.log-line:last .remove!
  $ \#main .fadeOut -> $ \#again .show!
$ \#next .click ->
  score++
  reason = $ \#reason .val! .replace(/[\n,]/g \，)
  choice = $ \.choice.green .attr \id
  row = "#key,#choice,#reason\n"
  switch choice
  | \x => $(\.log-x:last).addClass \positive; $(\.log-y:last).addClass \negative
  | \y => $(\.log-x:last).addClass \negative; $(\.log-y:last).addClass \positive
  | \z => $(\.log-x:last).addClass \warning; $(\.log-y:last).addClass \warning
  | \w => $(\.log-x:last).addClass \active; $(\.log-y:last).addClass \active
  window.total++ unless choice is \w
  window.unique++ unless choice is \w
  refresh-total!
  $ \.log-reason:last .text reason
  $.ajax dataType: 'jsonp', url: "https://www.moedict.tw/dodo/log/?log=#{ encodeURIComponent row }&offset=#{ window.seen.length }", success: ({delta}) -> refresh-seen (window.seen + delta)
  record += row
  $ \#progress-text .text "#score / #MAX"
  $ \#progress-bar .css \width "#{ score / MAX * 100 }%"
  if score >= MAX
    $ \#main .fadeOut -> $ \#again .show!
    return
  refresh!

LoadedScripts = {}
function getScript (src, cb)
  return cb! if LoadedScripts[src]
  LoadedScripts[src] = true
  $.ajax do
    type: \GET
    url: src
    dataType: \script
    cache: yes
    crossDomain: yes
    complete: cb

window.restart = restart = (idx='') ->
  window.location = document.URL.replace(/#.*$/, idx)

window.grok-hash = grok-hash = ->
  if location.hash is /^#(\d+)/
    refresh RegExp.$1
    return true
  return false

getScript \geili.js ->
  items := window.dodo-data
  return if grok-hash!
  do retry = ->
    return setTimeout retry, 100ms unless window.total
    refresh!
/*
getScript \data.js ->
  items := window.dodo-data
  getScript \oxynyms.js? ->
    items ++= window.dodo-oxynyms
    return if grok-hash!
    do retry = ->
      return setTimeout retry, 100ms unless window.total
      refresh!
*/

refresh-seen = (data) ->
  window.seen = data
  window.total = 0
  window.unique = 0
  processed = '\n'
  for line in data.split(/[\r\n]/) | line is /^([^,]+,[^,]+),[xyz]/
    key = RegExp.$1
    window.total++
    window.unique++ unless ~processed.index-of(key)
    processed += key
  refresh-total!

$.get "https://www.moedict.tw/dodo/log.txt?_=#{ Math.random! }" refresh-seen

refresh-total = window.refresh-total = ->
  return setTimeout refresh-total, 100ms unless items.length
  if window.total < items.length
    percent = Math.floor(window.total / items.length * 1000) / 10
    text = "第一階段「初校」。目前進度：#{window.total} / #{ items.length } (#percent%)"
  else if window.unique < items.length
    percent = Math.floor(window.unique / items.length * 1000) / 10
    text = "第二階段「交叉比對」。目前進度：#{window.unique} / #{ items.length } (#percent%)"
  else
    percent = 100
    text = "所有的源資料和備註都已寄送至教育部，非常感謝大家熱心參與！(1990/1990)"
  $ \#total-bar .css \width "#percent%"
  return $ \#total-text .text text if $ \#total-text .text!
  <- setTimeout _, 500ms
  $ \#total-text .hide! .text text .fadeIn \fast

function pick-item (idx)
  idx ||= Math.floor(Math.random! * items.length)
  result = try items[+idx]
  return pick-item! unless result
  items[idx] = null
  hash = "##idx"
  if location.hash is /^#(\d+)/ and "#{location.hash}" isnt hash
    try history.pushState null, null, hash
      catch => location.replace hash
  $ \#idx .text "##idx" .attr \href "https://www.moedict.tw/dodo/##idx"
  $ \.share.button .each ->
    $(@).attr \href "#{ $(@).data(\href) }%23#idx"
  return "#result\n#idx"

function refresh (fixed-idx)
  [book, x-key, x, y-key, y, idx] = pick-item(fixed-idx)  / '\n'
  key := "#x-key,#y-key"
  /*
  if not fixed-idx and ~window.seen.indexOf "\n#key,"
    # Reroll with 99% certainty if it's judged before
    # Reroll with 75% certainty if it's passed before
    factor = if window.seen is //\n#key,[xyz]// then 100 else 4
    return refresh! if Math.floor(Math.random! * factor)
  */
  $ \#book .text book
  $ \#x .html x.replace(/`/g, \<b>).replace(/~/g, \</b>)
  $ \#y .html y.replace(/`/g, \<b>).replace(/~/g, \</b>)
  $ \#x-key .text x-key
  $ \#y-key .text y-key
  $ \#x-key-link .attr href: "https://www.moedict.tw/##{ x-key }" target: \_blank
  $ \#y-key-link .attr href: "https://www.moedict.tw/##{ y-key }" target: \_blank

  $ \#log .append $(\<tr/> class: \log-line).append(
    $(\<td/> class: \book).text(book).append do
      $("<span><br></span>").append do
        $(\<a/> class: 'ui button mini key-link' href: "##idx" target: \_blank).text "重做"
          .prepend $("<i class='icon repeat'></i>")
    $(\<td/> class: \log-x).html($ \#x .html!).append do
      $("<span><br></span>").append do
        $(\<a/> class: \key-link href: "https://www.moedict.tw/##{ x-key }" target: \_blank).text x-key
          .prepend $("<i class='icon external url'></i>")
    $(\<td/> class: \log-y).html($ \#y .html!).append do
      $("<span><br></span>").append do
        $(\<a/> class: \key-link href: "https://www.moedict.tw/##{ y-key }" target: \_blank).text y-key
          .prepend $("<i class='icon external url'></i>")
    $(\<td/> class: \log-reason)
  )

  $ \.do-search .attr \target \_blank

  if book is /^「/
    $ \#key-links .show!
    $ \#chain-links .hide!
    $ \#type .text "引文用字"
    $ \.do-search.x .attr \href "https://www.google.com.tw/\#q=\"#{ x.replace(/[`~「」]/g '').replace(/﹍+/, '*') }\""
    $ \.do-search.y .attr \href "https://www.google.com.tw/\#q=\"#{ y.replace(/[`~「」]/g '').replace(/﹍+/, '*') }\""
    $ \#maybe-duplicate .hide!
    $ \#example .text ''
    #「送」：為離去的人送行或相陪到目的地。|例：「送別」、「送親」、「送孩子去幼稚園」。
    if book is /\|/
      example = book
      book -= /\|.*/
      example -= /.*\|/
      $ \#book .text book
      $ \#example .text(example - /。$/)
      $ \a.ui.mini.button.tag .hide!
      $ \#reason .attr \placeholder ''
      $ \#next .addClass \disabled
    $ \#x-key-link .attr href: "https://www.moedict.tw/~#{ x-key }" target: \_blank
  else if book is \教育部重編國語辭典修訂本
    $ \#chain-links .text ''
    comma = ""
    for chunk in (y - /中.*/ - /的意思.*/ - /[「」]/g).split \、
      $ \#chain-links .append comma .append do
        $(\<a/> class: \key-link href: "https://www.moedict.tw/##chunk" target: \_blank).text "「#{chunk}」"
          .prepend $("<i class='icon external url'></i>")
      comma = \、
    $ \#key-links .hide!
    $ \#chain-links .show!
    $ \#type .text "相似相反詞類"
    $ \.do-search.x .attr \href "https://www.google.com.tw/\#q=\"#x-key\" \"#y-key\" \"反義\""
    $ \.do-search.y .attr \href "https://www.google.com.tw/\#q=\"#x-key\" \"#y-key\" \"同義\""
  else
    $ \#key-links .show!
    $ \#chain-links .hide!
    $ \#type .text "引文用字"
    $ \.do-search.x .attr \href "https://www.google.com.tw/\#q=\"#{ x.replace(/[`~「」]/g '') }\""
    $ \.do-search.y .attr \href "https://www.google.com.tw/\#q=\"#{ y.replace(/[`~「」]/g '') }\""

  $ \#reason .val ''
  $ \#proceed .fadeOut \fast
  $ \#notice .fadeIn \fast
  $ \.choice .removeClass \green
  $ \.choice .off \click .click ->
    $ \.choice .removeClass \green
    $(@).addClass \green
    if $(@).attr('id') is \w
      $ \#next .removeClass \disabled
      $ \#reason .addClass \disabled
      $ \#reason-prompt .text '我覺得：a.這是現在國語會用的動詞，但兩個都不可以填入名詞；或是b. 這是現在國語不會用的動詞。'
    else
      $ \#reason-prompt .text '我覺得底線處可填入的名詞為：'
      $ \#reason .removeClass \disabled
      $ \#reason .one \change -> $ \#next .removeClass \disabled
      $ \#reason .one \keydown -> $ \#next .removeClass \disabled
    $ \.tag .off \click .click ->
      $ \#reason .val ~> "#{ $ \#reason .val! }[#{ $(@).text! }]"
    <- $ \#notice .fadeOut \fast
    <- $ \#proceed .fadeIn \fast
    $ \#reason .focus!
