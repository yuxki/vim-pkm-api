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

let s:spaces = '                                '
function! s:DiffSpace(a, b)
  let s:diff = a:a - a:b
  if s:diff <= 0
    return ''
  endif

  while s:diff > len(s:spaces)
    let s:spaces = s:spaces.s:spaces
  endwhile

  return s:spaces[0:s:diff - 1]
endfunction

function! pkm#PopupKeyMenu()
  let s:popup_key_menu = {}

  " Constructor------------------------------------------------------------------------------------
  let s:popup_key_menu.what = []
  let s:popup_key_menu.keys ='abcdefimnopqrstuvwyz'
  let s:popup_key_menu.max_cols_lines = 1
  let s:popup_key_menu.delimiter = ' '
  let s:popup_key_menu.ignorecase = 0
  let s:popup_key_menu.page_guide = 1
  let s:popup_key_menu.align = 1
  let s:popup_key_menu.fix_width = 1
  let s:popup_key_menu.fix_height = 1
  let s:popup_key_menu.vert_mode = 0
  let s:popup_key_menu.xclose = 1
  let s:popup_key_menu.next_page_key = 'l'
  let s:popup_key_menu.prev_page_key = 'h'
  let s:popup_key_menu.key_guide = '[%k] '
  let s:popup_key_menu.page_guides = [
        \ '       (%p) [%n] >>',
        \ '<< [%v] (%p) [%n] >>',
        \ '<< [%v] (%p)       ',
        \ ]
  let s:popup_key_menu.options = #{}

  " popup_key_menu.__InitPageGuides----------------------------------------------------------------
  function! s:popup_key_menu.__InitPageGuides() dict
    let s:guides = []
    for guide in self.page_guides
      call add(s:guides, substitute(
            \ substitute(guide, '%n', self.next_page_key, 'g'),
            \ '%v', self.prev_page_key, 'g'))
    endfor
    return s:guides
  endfunction

  " popup_key_menu.__PageGuide---------------------------------------------------------------------
  function! s:popup_key_menu.__PageGuide(guides, page_number) dict
      if a:page_number == 0
        let s:guide_index = 0
      elseif a:page_number == len(self.pages) - 1
        let s:guide_index = 2
      else
        let s:guide_index = 1
      endif
      return substitute(a:guides[s:guide_index], '%p', a:page_number, 'g')
  endfunction

  " popup_key_menua.Load---------------------------------------------------------------------------
  function! s:popup_key_menu.Load(what) dict
    let self.what = a:what

    let s:key_number = 0
    let s:col_number = 0
    let s:key_max = self.__KeepInKeyRange()
    let s:col_max = self.__KeepInColRange()

    let s:cols = []
    let s:lines = []
    let s:pages = []

    for w in self.what
      call add(s:cols, substitute(self.key_guide ,'%k', self.keys[(s:key_number % s:key_max)], 'g').w)
      let s:key_number += 1
      let s:col_number += 1

      if (s:col_number % s:col_max) > 0
        let s:line = s:line.self.delimiter
      endif

      if (s:col_number % s:col_max) == 0
        call add(s:lines, s:cols)
        let s:cols = []
        let s:col_number = 0
      endif

      if (s:key_number % s:key_max) == 0 || s:key_number == len(self.what)
        if len(s:cols) > 0
          call add(s:lines, s:cols)
          let s:cols = []
          let s:col_number = 0
        endif

        call add(s:pages, s:lines)
        let s:lines = []
      endif
    endfor

    " convert to vertical align
    if self.vert_mode
      let s:vert_pages = []
      for lines in s:pages
        let s:vert_lines = []
        for c in range(0, s:col_max - 1)
          let s:vert_cols = []
          for l in range(0, len(lines) - 1)
            if len(lines[l]) - 1 >= c
              call add(s:vert_cols, lines[l][c])
            endif
          endfor
          call add(s:vert_lines, s:vert_cols)
        endfor
        call add(s:vert_pages, s:vert_lines)
      endfor
      let s:pages = s:vert_pages
    endif

    " max col length list
    let s:max_col_lens = []
    if self.align
      for i in range(1, len(s:pages[0][0]))
        call add(s:max_col_lens, 0)
      endfor
    endif

    for i in range(0, len(s:max_col_lens) - 1)
      for lines in s:pages
        for cols in lines
          if len(cols) - 1 >= i && len(cols[i]) > s:max_col_lens[i]
            let s:max_col_lens[i] = len(cols[i])
          endif
        endfor
      endfor
    endfor

    " max lines
    let s:max_line_number = len(s:pages[0])

    let self.pages = []
    for lines in s:pages
      let s:page = []
      for cols in lines
        let s:line = ''
        let s:col_nr = 0
        for w in cols
          if self.align
            let s:line = s:line.w.s:DiffSpace(s:max_col_lens[s:col_nr], len(w)).self.delimiter
          else
            let s:line = s:line.w.self.delimiter
          endif
          let s:col_nr += 1
        endfor
        " fix width
        if self.fix_width
          for maxl in s:max_col_lens[s:col_nr:]
            let s:line = s:line.s:DiffSpace(maxl + len(self.delimiter), 0)
          endfor
        endif
        call add(s:page, s:line)
      endfor
      " fix height
      if self.fix_height
        while len(s:page) < s:max_line_number
          call add(s:page, '')
        endwhile
      endif
      call add(self.pages, s:page)
    endfor


    if self.page_guide && len(s:pages) > 1
      let s:del_len = len(self.delimiter)
      for i in range(0, len(s:max_col_lens) - 1)
        let s:max_col_lens[i] += s:del_len
      endfor

      let s:window_length = 0
      for l in s:max_col_lens
        let s:window_length += l
      endfor

      let s:page_guides = self.__InitPageGuides()
      for i in range(0, len(self.pages) - 1)
        let s:guide_line = self.__PageGuide(s:page_guides, i)

        if self.align
          let s:guide_spaces = s:DiffSpace(s:window_length, len(s:guide_line))
          if len(s:guide_line) > 1
            let s:guide_line =
                  \ s:guide_spaces[0:(len(s:guide_spaces) / 2) - 1]
                  \.s:guide_line
                  \.s:guide_spaces[(len(s:guide_spaces) / 2): -1]
          endif
        endif
        call add(self.pages[i], s:guide_line)
      endfor
    endif

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
    return len(self.keys)
  endfunction

  " popup_key_menu.__KeepInColRange----------------------------------------------------------------
  function! s:popup_key_menu.__KeepInColRange() dict
    return self.max_cols_lines > 0 ?
          \ self.max_cols_lines <= self.__KeepInKeyRange() ? self.max_cols_lines : self.__KeepInKeyRange()
          \ : 1
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
    return self.winid
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
