" Filename: pkm.vim
" Version: 0.1.0
" Author: yuxki
" Repository: https://github.com/yuxki/vim-pkm-api
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

let s:pkm_api_popup_key_menus = {}
let s:pkm_api_popup_key_menu_id = 1000

function! pkm#PkmMenus()
  return s:pkm_api_popup_key_menus
endfunction

function! pkm#NextId()
  return s:pkm_api_popup_key_menu_id
endfunction

function! pkm#Exists(id)
  return has_key(s:pkm_api_popup_key_menus, a:id)
endfunction

function! pkm#Clear()
  for value in values(s:pkm_api_popup_key_menus)
    if index(popup_list(), value.winid) >= 0
      call popup_close(value.winid)
    endif
  endfor
  let s:pkm_api_popup_key_menus = {}
endfunction

function! s:CallPopupFilter(winid, key)
  for [key, value] in items(s:pkm_api_popup_key_menus)
    if value['winid'] == a:winid
      return s:pkm_api_popup_key_menus[key].Filter(a:winid, a:key)
    endif
  endfor
  return 0
endfunction

function! s:CallPopupCallback(winid, secondarg)
  for [key, value] in items(s:pkm_api_popup_key_menus)
    if value['winid'] == a:winid
      return s:pkm_api_popup_key_menus[key].OnClose(a:winid, a:secondarg)
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
  " General
  let s:popup_key_menu.winid = -1
  " Load
  let s:popup_key_menu.what = []
  let s:popup_key_menu.pages = []
  let s:popup_key_menu.keys ='abcdefimnopqrstuvwyz'
  let s:popup_key_menu.max_cols_lines = 1
  let s:popup_key_menu.item_border = ' '
  let s:popup_key_menu.add_page_guide = 1
  let s:popup_key_menu.align = 1
  let s:popup_key_menu.col_width = 'auto' " 'auto', 'max', number, numbers list
  let s:popup_key_menu.fix_cols = 0
  let s:popup_key_menu.fix_lines = 0
  let s:popup_key_menu.vertical = 0
  let s:popup_key_menu.xclose = 1
  let s:popup_key_menu.key_guide = '[%k] '
  let s:popup_key_menu.page_guides = [
        \ '       (%p) [%n] >>',
        \ '<< [%v] (%p) [%n] >>',
        \ '<< [%v] (%p)       ',
        \ ]
  " Filter
  let s:popup_key_menu.ignorecase = 0
  let s:popup_key_menu.next_page_key = 'L'
  let s:popup_key_menu.prev_page_key = 'H'
  let s:popup_key_menu.focus = 1
  " Open
  let s:popup_key_menu.options = #{}

  " popup_key_menu.__WorkingPages------------------------------------------------------------------
  function! s:popup_key_menu.__WorkingPages() dict
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

    return s:pages
  endfunction

  " popup_key_menu.__Convert2Vert------------------------------------------------------------------
  function! s:popup_key_menu.__Convert2Vert(w_pages) dict
    let s:vert_pages = []

    for lines in a:w_pages
      let s:vert_lines = []
      for c in range(0, len(lines[0]) - 1)
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

    return s:vert_pages
  endfunction

  " popup_key_menu.__ColLens-------------------------------------------------------------------
  function! s:popup_key_menu.__ColLens(w_pages) dict
    let s:col_lens = []

    if !self.align
      return s:col_lens
    endif

    let s:start = type(self.col_width) == 0 ? self.col_width : 0
    for i in range(1, len(a:w_pages[0][0]))
      call add(s:col_lens, s:start)
    endfor

    if type(self.col_width) == 3
      for i in range(0, len(s:col_lens) - 1)
        if i >= len(self.col_width)
          break
        endif
        let s:col_lens[i] = self.col_width[i]
      endfor
    endif

    for i in range(0, len(s:col_lens) - 1)
      for lines in a:w_pages
        for cols in lines
          if len(cols) - 1 >= i && len(cols[i]) > s:col_lens[i]
            let s:col_lens[i] = len(cols[i])
          endif
        endfor
      endfor
    endfor

    if type(self.col_width) == 1 && self.col_width == 'max'
      let s:max = max(s:col_lens)
      call map(s:col_lens, s:max)
    endif

    return s:col_lens
  endfunction

  " popup_key_menu.__FixLines----------------------------------------------------------------------
  function! s:popup_key_menu.__FixLines(w_pages, col_lens, line_number) dict
    let s:blank_cols = []

    while len(s:blank_cols) < len(a:col_lens)
      call add(s:blank_cols, '')
    endwhile

    for lines in a:w_pages
      while len(lines) < a:line_number
        call add(lines, s:blank_cols)
      endwhile
    endfor
  endfunction

  " popup_key_menu.__FixCols-----------------------------------------------------------------------
  function! s:popup_key_menu.__FixCols(w_pages, col_lens) dict
    for lines in a:w_pages
      for cols in lines
        while len(cols) < len(a:col_lens)
          call add(cols, '')
        endwhile
      endfor
    endfor
  endfunction

  " popup_key_menu.__PageGuide---------------------------------------------------------------------
  function! s:popup_key_menu.__PageGuide(page_number, guide_index) dict
    return substitute(
          \ substitute(
          \ substitute(self.page_guides[a:guide_index],
          \ '%n', self.next_page_key, 'g'),
          \ '%v', self.prev_page_key, 'g'),
          \ '%p', a:page_number, 'g')
  endfunction

  " popup_key_menu.__PageGuides--------------------------------------------------------------------
  function! s:popup_key_menu.__PageGuides(w_pages, col_lens) dict
    let s:guides = []

    if len(a:w_pages) < 2 || !self.add_page_guide
      return s:guides
    endif

    let s:guide_width = 0
    for l in a:col_lens
      let s:guide_width += l + len(self.item_border)
    endfor
    let s:guide_width -= len(self.item_border) " sub last column length

    let s:page_number = 0
    for page in a:w_pages
      if s:page_number == 0
        let s:guide_index = 0
      elseif s:page_number == len(a:w_pages) - 1
        let s:guide_index = 2
      else
        let s:guide_index = 1
      endif

      let s:guide = self.__PageGuide(s:page_number, s:guide_index)

      if self.align
        let s:guide_spaces = s:DiffSpace(s:guide_width, len(s:guide))
        if len(s:guide_spaces) > 1
          let s:guide =
                \ s:guide_spaces[0:(len(s:guide_spaces) / 2) - 1]
                \.s:guide
                \.s:guide_spaces[(len(s:guide_spaces) / 2): -1]
        endif
      endif

      call add(s:guides, s:guide)
      let s:page_number += 1
    endfor

    return s:guides
  endfunction

  " popup_key_menu.__LoadPages---------------------------------------------------------------------
  function! s:popup_key_menu.__LoadPages(w_pages, col_lens, page_guides) dict
    let self.pages = []

    for lines in a:w_pages
      let s:page = []
      for cols in lines
        let s:line = ''
        let s:col_nr = 0
        for w in cols
          let s:border = s:col_nr > 0 ?
                  \ len(w) > 0 ?
                  \ self.item_border : s:DiffSpace(self.item_border, 0)
                \ : ''
          if self.align
            let s:line = s:line.s:border.w.s:DiffSpace(a:col_lens[s:col_nr], len(w))
          else
            let s:line = s:line.s:border.w
          endif
          let s:col_nr += 1
        endfor
        call add(s:page, s:line)
      endfor
      call add(self.pages, s:page)
    endfor

    for i in range(0, len(s:page_guides) - 1)
      call add(self.pages[i], s:page_guides[i])
    endfor
  endfunction

  " popup_key_menu.Load----------------------------------------------------------------------------
  function! s:popup_key_menu.Load(what) dict
    let self.what = a:what
    let s:w_pages = self.__WorkingPages()

    " convert to vertical align
    if self.vertical
      let s:w_pages = self.__Convert2Vert(s:w_pages)
    endif

    " get max cols and lines
    let s:max_col_lens = self.__ColLens(s:w_pages)
    let s:max_line_number = len(s:w_pages[0])

    " fix lines and cols
    if self.align
      if self.fix_lines
        call self.__FixLines(s:w_pages, s:max_col_lens, s:max_line_number)
      endif
      if self.fix_cols
        call self.__FixCols(s:w_pages, s:max_col_lens)
      endif
    endif

    " get page guides
    let s:page_guides = self.__PageGuides(s:w_pages, s:max_col_lens)

    " load working pages into self.pages
    call self.__LoadPages(s:w_pages, s:max_col_lens, s:page_guides)

    return self
  endfunction

  " popup_key_menu.__XClose------------------------------------------------------------------------
  function! s:popup_key_menu.__XClose(winid, key) dict
    if a:key ==# 'x'
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

    let s:of_ret = self.OnFilter(a:winid, a:key)
    if s:of_ret >= 1
      return 1
    elseif s:of_ret < 0
      return 0
    endif

    if self.xclose
      if self.__XClose(a:winid, a:key)
        return 1
      endif
    endif

    let s:key_max = self.__KeepInKeyRange()

    if a:key ==# self.next_page_key
      if self.__AfterPageKeysRest() > 0
        let self.page_number += 1
        call popup_settext(a:winid, self.pages[self.page_number])
      endif
      return 1
    elseif a:key ==# self.prev_page_key
      if self.page_number > 0
        let self.page_number -= 1
        call popup_settext(a:winid, self.pages[self.page_number])
      endif
      return 1
    endif

    " TODO support CTRL + key
    if len(a:key) == 1 " avoid interruption by other program
      if (self.__AfterPageKeysRest() >= 0 && self.keys[0:s:key_max - 1] =~# a:key) ||
       \ (len(self.what) % s:key_max > 0 && self.keys[0:(len(self.what) % s:key_max) - 1] =~# a:key)
        call self.OnKeySelect(a:winid, self.__SearchKeyIndex(a:key) + (self.page_number * s:key_max))
        return 1
      endif
    endif

    return self.focus == 1 ? 1 : 0
  endfunction

  " popup_key_menu.__InitPopupOptions--------------------------------------------------------------
  function! s:popup_key_menu.__InitPopupOptions(options) dict
    let s:scirpt_func_prefix = '<SNR>'.s:GetScriptNumber().'_'
    let self.options = #{
          \ filter: s:scirpt_func_prefix.'CallPopupFilter',
          \ callback: s:scirpt_func_prefix.'CallPopupCallback',
          \ mapping: 1,
          \}

    for [key, value] in items(a:options)
      let self.options[key] = value
    endfor
  endfunction

  " popup_key_menu.Open----------------------------------------------------------------------------
  function! s:popup_key_menu.Open(options) dict
    call self.__InitPopupOptions(a:options)

    if len(self.pages) <= 0
      return self
    endif

    if index(popup_list(), self.winid) >= 0
      return self
    endif

    let self.page_number = 0
    let self.winid = popup_create(self.pages[self.page_number], self.options)
    call self.OnOpen(self.winid)

    return self
  endfunction

  " popup_key_menu.Remove--------------------------------------------------------------------------
  function! s:popup_key_menu.Remove() dict
    call remove(s:pkm_api_popup_key_menus, self.pkm_api_popup_key_menu_id)
  endfunction

  " Handlers ======================================================================================

  " popup_key_menu.OnKeySelect---------------------------------------------------------------------
  function! s:popup_key_menu.OnKeySelect(winid, index) dict
  endfunction

  " popup_key_menu.OnFilter------------------------------------------------------------------------
  function! s:popup_key_menu.OnFilter(winid, key) dict
  endfunction

  " popup_key_menu.OnOpen--------------------------------------------------------------------------
  function! s:popup_key_menu.OnOpen(winid) dict
  endfunction

  " popup_key_menu.OnClose-------------------------------------------------------------------------
  function! s:popup_key_menu.OnClose(winid, secondarg) dict
  endfunction

  let s:pkm_api_popup_key_menus[string(s:pkm_api_popup_key_menu_id)] = s:popup_key_menu
  let s:popup_key_menu.pkm_id = s:pkm_api_popup_key_menu_id
  let s:pkm_api_popup_key_menu_id += 1

  return s:popup_key_menu
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
