" MIT License
"
" Copyright (c) 2021 Yuxki
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in all
" copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
" SOFTWARE.

let s:keys = 'abcdefimnopqrstuvwyz'

let s:popup_filter = {}
" TODO  rename to OnKeyPress
" TODO  add OnOpen
function! s:popup_filter.invoke(winid, key) dict

  if a:key == 'l' && s:page_number < s:pages_max_len - 1
    echo s:page_number
    let s:page_number += 1
    call popup_settext(a:winid, s:pages[s:page_number])
  endif

  if a:key == 'h' && s:page_number > 0
    let s:page_number -= 1
    call popup_settext(a:winid, s:pages[s:page_number])
  endif

  if a:key == 'x'
    call popup_close(a:winid)
    return 1
  endif

  if len(a:key) == 1
    if ((s:modulo == 0 || s:page_number < s:pages_max_len - 1) && s:keys[0:9 - 1] =~# a:key) ||
          \ s:keys[0:s:modulo - 1] =~# a:key
      call self.callback.invoke(a:winid, matchstrpos(s:keys, a:key)[1] + (s:page_number * 9))
    endif
    return 1
  endif

  return 1
endfunction

function! s:CallPopupFilter(winid, key)
  return s:popup_filter.invoke(a:winid, a:key)
endfunction

function! s:GetScriptNumber()
  return matchstr(expand('<SID>'), '<SNR>\zs\d\+\ze_')
endfunction

" TODO popup option nubmer over 10
function! PopupKeyMenu(what, callback, options)
  if len(a:what) <= 0
    return
  endif

  let s:pages_max_len = len(a:what) / 9
  let s:modulo = len(a:what) % 9
  if s:modulo > 0
    let s:pages_max_len += 1
  endif

  let s:pages = []
  let s:page = []
  let s:key_number = 0

  for w in a:what
    if s:key_number == 0 || s:key_number == 9
      let s:page = []
      let s:key_number = 0
    endif

    call add(s:page, '['.s:keys[s:key_number].']'." ". ' '. w)
    let s:key_number += 1

    if s:key_number == 9 || (len(s:pages) == s:pages_max_len - 1 && s:key_number == s:modulo)
      let s:pages_len = len(s:pages)
      if s:pages_len == 0
        call add(s:page, '  ('.s:pages_len.') [l] ->  ')
      elseif len(s:pages) < s:pages_max_len - 1
        call add(s:page, '  <- [h] ('.s:pages_len.') [l] ->  ')
      else
        call add(s:page, '  <- [h] ('.s:pages_len.')  ')
      endif
      call add(s:pages, s:page)
    endif
  endfor

  " for page in s:pages
  "   echo page
  " endfor

  " let s:what = []
  " let s:key_number = 0
  " let s:keys = 'abcdefghijklmnopqrstuvwyz'
  " for w in a:what
  "   "call add(s:what, '['. string(s:key_number).']'." ". ' '. w)
  "   call add(s:what, '['.s:keys[s:key_number].']'." ". ' '. w)
  "   let s:key_number += 1
  " endfor

  let s:options = #{ close: 'button', filter: '<SNR>'.s:GetScriptNumber().'_CallPopupFilter' }
  for [key, value] in items(a:options)
    let s:options[key] = value
  endfor

  let s:popup_filter.max_index = s:key_number
  let s:popup_filter.callback = a:callback

  let s:page_number = 0
  let s:winid = popup_create(s:pages[s:page_number], s:options)
endfunction
