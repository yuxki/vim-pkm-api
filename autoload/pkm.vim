" Filename: pkm.vim
" Version: 0.1.0
" Author: yuxki
" Last Change: 2021/12/24
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

let s:save_cpo = &cpo
set cpo&vim

if !exists('g:pkm_api_popup_key_menus')
  let g:pkm_api_popup_key_menus = {}
endif

if !exists('g:pkm_api_popup_key_menu_id')
  let g:pkm_api_popup_key_menu_id = 1000
endif

function! s:CallPopupFilter(winid, key)
  for [key, value] in items(g:pkm_api_popup_key_menus)
    if value['winid'] == a:winid
      return g:pkm_api_popup_key_menus[key].Filter(a:winid, a:key)
    endif
  endfor
  return 0
endfunction

function! s:CallPopupCallback(winid, key)
  for [key, value] in items(g:pkm_api_popup_key_menus)
    if value['winid'] == a:winid
      return g:pkm_api_popup_key_menus[key].OnClose(a:winid, a:key)
    endif
  endfor
  return 0
endfunction

function! s:GetScriptNumber()
  return matchstr(expand('<SID>'), '<SNR>\zs\d\+\ze_')
endfunction

function! pkm#PopupKeyMenu()
  let s:popup_key_menu = {}

  " Constructor------------------------------------------------------------------------------------
  let s:popup_key_menu.what = []
  let s:popup_key_menu.keys ='abcdefimnopqrstuvwyz'
  let s:popup_key_menu.key_max = 9
  let s:popup_key_menu.col_max = 1
  let s:popup_key_menu.delimiter = '   '
  let s:popup_key_menu.ignorecase = 0
  let s:popup_key_menu.page_guide = 1
  let s:popup_key_menu.xclose = 1
  let s:popup_key_menu.next_page_key = 'l'
  let s:popup_key_menu.prev_page_key = 'h'
  let s:popup_key_menu.key_guide = '[%k] '
  let s:popup_key_menu.page_guides = [
        \ '  (%p) [%n] >>  ',
        \ '  << [%v] (%p) [%n] >>  ',
        \ '  << [%v] (%p)  ',
        \ ]
  let s:popup_key_menu.options = #{}

  " popup_key_menu.__PageGuides--------------------------------------------------------------------
  function! s:popup_key_menu.__InitPageGuides() dict
    let s:guides = []
    for guide in self.page_guides
      call add(s:guides, substitute(
            \ substitute(guide, '%n', self.next_page_key, 'g'),
            \ '%v', self.prev_page_key, 'g'))
    endfor
    return s:guides
  endfunction

  " popup_key_menua.Load---------------------------------------------------------------------------
  function! s:popup_key_menu.Load(what) dict
    let self.what = a:what
    let self.pages = []

    let s:page = []
    let s:key_number = 0
    let s:col_number = 0
    let s:line = ''
    let s:key_max = self.__KeepInKeyRange()
    let s:col_max = self.__KeepInColRange()
    let s:page_guides = self.__InitPageGuides()

    for w in self.what
      let s:line = s:line.substitute(self.key_guide ,'%k', self.keys[(s:key_number % s:key_max)], 'g').w
      let s:key_number += 1
      let s:col_number += 1

      if (s:col_number % s:col_max) > 0
        let s:line = s:line.self.delimiter
      endif

      if (s:col_number % s:col_max) == 0
        call add(s:page, s:line)
        let s:line = ''
        let s:col_number = 0
      endif

      if (s:key_number % s:key_max) == 0 || s:key_number == len(self.what)
        if len(s:line) > 0
          call add(s:page, s:line)
          let s:line = ''
          let s:col_number = 0
        endif

        if len(self.what) <= s:key_max
          call add(self.pages, s:page)
          break
        endif

        let self.pages_len = len(self.pages)
        if self.page_guide
          if self.pages_len == 0
            let s:guide_index = 0
          elseif (len(self.pages) + 1) * s:key_max < len(self.what)
            let s:guide_index = 1
          else
            let s:guide_index = 2
          endif
          call add(s:page, substitute(s:page_guides[s:guide_index], '%p', self.pages_len, 'g'))
        endif
        call add(self.pages, s:page)
        let s:page = []
      endif
    endfor
    return self
  endfunction

  " popup_key_menu.__XClose------------------------------------------------------------------------
  function! s:popup_key_menu.__XClose(winid, key) dict
    if a:key == 'x'
      call popup_close(a:winid, a:key)
      return 1
    endif
    return 0
  endfunction

  " popup_key_menu.__KeepInKeyRange----------------------------------------------------------------
  function! s:popup_key_menu.__KeepInKeyRange() dict
    return self.key_max > 0 ? self.key_max <= len(self.keys) ? self.key_max : len(self.keys) : 1
  endfunction

  " popup_key_menu.__KeepInColRange----------------------------------------------------------------
  function! s:popup_key_menu.__KeepInColRange() dict
    return self.col_max > 0 ? self.col_max <= self.__KeepInKeyRange() ? self.col_max : self.__KeepInKeyRange() : 1
  endfunction

  " popup_key_menu.__AfterPageKeysRest-------------------------------------------------------------
  function! s:popup_key_menu.__AfterPageKeysRest() dict
    let s:key_max = self.__KeepInKeyRange()
    return len(self.what) - ((self.page_number + 1) * s:key_max)
  endfunction

  " popup_key_menu.__SearchKeyIndex----------------------------------------------------------------
  function! s:popup_key_menu.__SearchKeyIndex(key) dict
    return matchstrpos(self.keys, self.ignorecase ? a:key : a:key.'\C')[1]
  endfunction

  " popup_key_menu.Filter--------------------------------------------------------------------------
  function! s:popup_key_menu.Filter(winid, key) dict
    if self.OnKeyPress(a:winid, a:key)
      return 1
    endif

    if self.xclose
      if self.__XClose(a:winid, a:key)
        return 1
      endif
    endif

    let s:key_max = self.__KeepInKeyRange()

    if a:key == self.next_page_key && self.__AfterPageKeysRest() > 0
      let self.page_number += 1
      call popup_settext(a:winid, self.pages[self.page_number])
      return 1
    elseif a:key == self.prev_page_key && self.page_number > 0
      let self.page_number -= 1
      call popup_settext(a:winid, self.pages[self.page_number])
      return 1
    endif

    " TODO support CTRL + key
    if len(a:key) == 1 " avoid interruption by other program
      if (self.__AfterPageKeysRest() >= 0 && self.keys[0:s:key_max - 1] =~# a:key) ||
       \ (len(self.what) % s:key_max > 0 && self.keys[0:(len(self.what) % s:key_max) - 1] =~# a:key)
        call self.OnKeySelect(a:winid, self.__SearchKeyIndex(a:key) + (self.page_number * s:key_max))
      endif
      return 1
    endif

    return 0
  endfunction

  " popup_key_menu.__InitPopupOptions--------------------------------------------------------------
  function! s:popup_key_menu.__InitPopupOptions(options) dict
    let s:scirpt_func_prefix = '<SNR>'.s:GetScriptNumber().'_'
    let self.options = #{
          \ filter: s:scirpt_func_prefix.'CallPopupFilter',
          \ callback: s:scirpt_func_prefix.'CallPopupCallback',
          \}

    if self.xclose
      let self.options['close'] = 'button'
    endif

    for [key, value] in items(a:options)
      let self.options[key] = value
    endfor
  endfunction

  " popup_key_menu.Open----------------------------------------------------------------------------
  function! s:popup_key_menu.Open(options) dict
    call self.__InitPopupOptions(a:options)

    if len(self.what) <= 0
      return
    endif

    let self.page_number = 0
    let self.winid = popup_create(self.pages[self.page_number], self.options)
    call self.OnOpen(self.winid)
  endfunction

  " popup_key_menu.Remove--------------------------------------------------------------------------
  function! s:popup_key_menu.Remove() dict
    call remove(g:pkm_api_popup_key_menus, self.pkm_api_popup_key_menu_id)
  endfunction

  " Handlers ======================================================================================

  " popup_key_menu.OnKeySelect---------------------------------------------------------------------
  function! s:popup_key_menu.OnKeySelect(winid, index) dict
  endfunction

  " popup_key_menu.OnKeyPress----------------------------------------------------------------------
  function! s:popup_key_menu.OnKeyPress(winid, key) dict
  endfunction

  " popup_key_menu.OnOpen--------------------------------------------------------------------------
  function! s:popup_key_menu.OnOpen(winid) dict
  endfunction

  " popup_key_menu.OnClose-------------------------------------------------------------------------
  function! s:popup_key_menu.OnClose(winid, key) dict
  endfunction

  let g:pkm_api_popup_key_menus[string(g:pkm_api_popup_key_menu_id)] = s:popup_key_menu
  let s:popup_key_menu.pkm_id = g:pkm_api_popup_key_menu_id
  let g:pkm_api_popup_key_menu_id += 1

  return s:popup_key_menu
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
