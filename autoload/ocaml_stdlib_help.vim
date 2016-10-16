let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('ocaml_stdlib_help')
let s:HTTP = s:V.import('Web.HTTP')
let s:XML = s:V.import('Web.XML')

function! ocaml_stdlib_help#search(arg) abort
  let yql = "select * from html where url='http://caml.inria.fr/pub/docs/manual-ocaml/libref/" . a:arg . ".html'"
  let response = s:HTTP.get("https://query.yahooapis.com/v1/public/yql", { 'q' : yql })
  let dom = s:XML.parse(response.content)
  let body = dom.find('body')
  let lines = []

  if empty(body)
    call s:echo_error_msg(a:arg . ' was not found.')
    return
  endif

  call s:create_window()

  let idx = s:find_h1_idx(body.child)
  for i in range(idx, len(body.child)-1)
    if type({}) == type(body.child[i]) && body.child[i].name ==# 'pre'
      let pre = substitute(body.child[i].value(), " \\+", " ", "g")
      call add(lines, pre)
      for j in range(i+1, len(body.child)-1)
        if type({}) == type(body.child[j])
          let dic = body.child[j]
          if dic.name ==# 'div'
            call add(lines, dic.value())
          elseif dic.name ==# 'table'
            call add(lines, s:format_table(dic))
          else
            break
          endif
        endif
      endfor
    endif
  endfor

  " write buffer
  let tmpfname = tempname()
  call writefile(lines, tmpfname)
  for line in readfile(tmpfname)
    let t = split(line, '\n')
    for inline in t
      call append(line('$'), inline)
    endfor
  endfor
endfunction

function! s:create_window() abort
  new
  setlocal buftype=nofile noswapfile filetype=ocaml
endfunction

function! s:find_h1_idx(list) abort
  let idx = 0
  for i in range(0, len(a:list)-1)
    if type({}) == type(a:list) && a:list[i].name ==# 'hr'
      let idx = i
      break
    endif
  endfor
  return idx
endfunction

function! s:format_table(table) abort
  let tbody = a:table.childNode('tbody')
  let ret = ''
  for tr in tbody.child
    let x = substitute(tr.value(), "\n", " ", "g")
    let x = substitute(x, " \\+", " ", "g")
    let ret = ret . x . "\n"
  endfor
  return ret
endfunction

function! s:echo_error_msg(msg) abort
  echohl ErrorMsg | echo 'ocaml_stdlib_help: ' . a:msg | echohl None
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
