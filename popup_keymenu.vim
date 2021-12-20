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

let s:popup_filter = {}
function! s:popup_filter.invoke(winid, key) dict
  if a:key =~# '\a' || a:key =~# ':'
    call popup_close(a:winid)
  elseif len(a:key) == 1 && a:key =~# '\d' && a:key >= 0 && a:key < self.max_index
    call self.callback.invoke(a:key)
    call popup_close(a:winid)
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

  let s:options = #{ close: 'button', filter: '<SNR>'.s:GetScriptNumber().'_CallPopupFilter' }
  for [key, value] in items(a:options)
    let s:options[key] = value
  endfor

  let s:what = []
  let s:key_number = 0
  for w in a:what
    call add(s:what, string(s:key_number) . ': '. w)
    let s:key_number += 1
  endfor

  let s:popup_filter.max_index = s:key_number
  let s:popup_filter.callback = a:callback

  return popup_create(s:what, s:options)
endfunction
