func! s:KeywordPosList(line)
  let start = 0
  let pos_list = []

  while 1
    let pos = matchstrpos(a:line, '\k\+', start)
    if pos[2] < 0
      break
    endif
    call add(pos_list, pos)
    let start = pos[2]
  endwhile
  return pos_list
endfunc

hi QuickWord term=reverse ctermbg=16 guibg=#000000
let s:pkm_id = ''
func! s:QuickWord()
  if !pkm#Exists(s:pkm_id)
    let s:pkm = pkm#PopupKeyMenu()
    let s:pkm.keys = 'abcdefgijkmnopqrstuvwyz'
    let s:pkm.max_cols_lines = len(s:pkm.keys)
    let s:pkm.key_guide = "%t%k"
    let s:pkm.ignorecase = 1
    let s:pkm.align = 0
    let s:pkm.item_border = ""
    let s:pkm.page_guides = ["%n>", "<%v %n>", "<%v"]

    func! s:pkm.OnOpen(winid)
      call setwinvar(a:winid, '&wincolor', 'QuickWord')
    endfunc

    func! s:pkm.OnFilter(winid, key) dict
      if a:key == ':'
        return -1
      endif

      if len(a:key) == 1
        if a:key =~# '\u'
          let self.endofword = 1
        else
          let self.endofword = 0
        endif
      endif
    endfunc

    func! s:pkm.OnKeySelect(winid, index) dict
      let pos = self.endofword == 0 ?
            \ self.pos_list[a:index][1] + 1 : self.pos_list[a:index][2]
      call cursor('.', pos)
      call popup_close(a:winid)
    endfunc
  endif

  let line = getline('.')
  let s:pkm.pos_list = s:KeywordPosList(line)

  let keywords = []
  let start = 0
  let keys_len = len(s:pkm.keys)
  for pos in s:pkm.pos_list
    if len(keywords) % keys_len == 0
      let start = 0
    endif

    let end = (pos[1] - 1) >= 0 ? (pos[1] - 1) : 0
    let space = end > 0 ? ' ' : ''
    let spaces = substitute(line[start:end], '[^\t]', space, 'g')

    call add(keywords, spaces)

    let start = pos[1] + 1
  endfor

  "let s:pkm.header = line
  call s:pkm.Load(keywords)

  let line_plus = len(s:pkm.pages) < 2 ? 1 : 2
  let options = #{
        \ filtermode: 'n',
        \ pos: 'botleft',
        \ line: 'cursor+' . line_plus,
        \ col: 'cursor-' . (virtcol('.') - 1) ,
        \ }
  call s:pkm.Open(options)
  let s:pkm_id = s:pkm.pkm_id
endfunc

nmap <silent> W :call <SID>QuickWord()<CR>
