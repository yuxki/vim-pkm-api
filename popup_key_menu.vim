" Filename: popup_key_menu.vim
" Version: 0.1.0
" Author: yuxki
" Last Change: 2021/12/22
"
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

if !exists('g:popup_key_menus')
  let g:popup_key_menus = {}
endif

if !exists('g:popup_key_menu_id')
  let g:popup_key_menu_id = 1000
endif

function! s:CallPopupFilter(winid, key)
  for [key, value] in items(g:popup_key_menus)
    if value['winid'] == a:winid
      return g:popup_key_menus[key].Filter(a:winid, a:key)
    endif
  endfor
  return 0
endfunction

function! s:CallPopupCallback(winid, key)
  for [key, value] in items(g:popup_key_menus)
    if value['winid'] == a:winid
      return g:popup_key_menus[key].OnClose(a:winid, a:key)
    endif
  endfor
  return 0
endfunction

function! s:GetScriptNumber()
  return matchstr(expand('<SID>'), '<SNR>\zs\d\+\ze_')
endfunction

function! PopupKeyMenu(what, options=#{})
  let s:popup_key_menu = {}

  " Constructor------------------------------------------------------------------------------------
  let s:popup_key_menu.what = a:what
  let s:popup_key_menu.keys ='abcdefimnopqrstuvwyz'
  let s:popup_key_menu.max_key_number = 9
  let s:popup_key_menu.col_number = 1
  let s:scirpt_func_prefix = '<SNR>'.s:GetScriptNumber().'_'
  let s:popup_key_menu.options = #{
        \ close: 'button',
        \ filter: s:scirpt_func_prefix.'CallPopupFilter',
        \ callback: s:scirpt_func_prefix.'CallPopupCallback',
        \}
  for [key, value] in items(a:options)
    let s:popup_key_menu.options[key] = value
  endfor

  " popup_key_menua.Init---------------------------------------------------------------------------
  function! s:popup_key_menu.Init() dict abort
    let self.pages_max_len = len(self.what) / self.max_key_number
    let self.modulo = len(self.what) % self.max_key_number
    if self.modulo > 0
      let self.pages_max_len += 1
    endif

    let self.pages = []
    let s:page = []
    let s:key_number = 0

    for w in self.what
      if s:key_number == 0 || s:key_number == self.max_key_number
        let s:page = []
        let s:key_number = 0
      endif
      call add(s:page, '['.self.keys[s:key_number].']'." ". ' '. w)
      let s:key_number += 1

      if s:key_number == self.max_key_number || (len(self.pages) == self.pages_max_len - 1 && s:key_number == self.modulo)
        let self.pages_len = len(self.pages)
        if self.pages_len == 0
          call add(s:page, '  ('.self.pages_len.') [l] ->  ')
        elseif len(self.pages) < self.pages_max_len - 1
          call add(s:page, '  <- [h] ('.self.pages_len.') [l] ->  ')
        else
          call add(s:page, '  <- [h] ('.self.pages_len.')  ')
        endif
        call add(self.pages, s:page)
      endif
    endfor
  endfunction

  " popup_key_menu.Filter--------------------------------------------------------------------------
  function! s:popup_key_menu.Filter(winid, key) dict abort
    if a:key == 'l' && self.page_number < self.pages_max_len - 1
      let self.page_number += 1
      call popup_settext(a:winid, self.pages[self.page_number])
    endif

    if a:key == 'h' && self.page_number > 0
      let self.page_number -= 1
      call popup_settext(a:winid, self.pages[self.page_number])
    endif

    if a:key == 'x'
      call popup_close(a:winid, a:key)
      return 1
    endif

    if len(a:key) == 1
      if ((self.modulo == 0 || self.page_number < self.pages_max_len - 1) && self.keys[0:self.max_key_number - 1] =~# a:key) ||
            \ self.keys[0:self.modulo - 1] =~# a:key
        call self.OnSelect(a:winid, matchstrpos(self.keys, a:key)[1] + (self.page_number * self.max_key_number))
      endif
      return 1
    endif

    return 1
  endfunction

  " popup_key_menu.Open----------------------------------------------------------------------------
  function! s:popup_key_menu.Open() dict abort
    if len(self.what) <= 0
      return
    endif

    let self.page_number = 0
    let self.winid = popup_create(self.pages[self.page_number], self.options)
    call self.OnOpen(self.winid)
  endfunction

  " popup_key_menu.Remove--------------------------------------------------------------------------
  function! s:popup_key_menu.Remove() dict abort
    call remove(g:popup_key_menus, self.popup_key_menu_id)
  endfunction

  " Event Handlers =================================================================================

  " popup_key_menu.OnSelect------------------------------------------------------------------------
  function! s:popup_key_menu.OnSelect(winid, index) dict abort
  endfunction

  " popup_key_menu.OnOpen--------------------------------------------------------------------------
  function! s:popup_key_menu.OnOpen(winid) dict abort
  endfunction

  " popup_key_menu.OnClose-------------------------------------------------------------------------
  function! s:popup_key_menu.OnClose(winid, key) dict abort
  endfunction

  let g:popup_key_menus[string(g:popup_key_menu_id)] = s:popup_key_menu
  let s:popup_key_menu.popup_key_menu_id = g:popup_key_menu_id
  let g:popup_key_menu_id += 1

  return s:popup_key_menu
endfunction