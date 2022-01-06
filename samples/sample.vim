 let s:colors = ['red', 'blue', 'yellow', 'orange', 'black']
 let s:options = #{
  \ padding: [0, 1, 0, 1],
  \ border: [1, 1, 1, 1],
  \ filtermode: 'n',
  \ }
 let s:pkm_id = ''

 function! SamplePkm()
   if !pkm#Exists(s:pkm_id)
     let s:pkm = pkm#PopupKeyMenu()            " #1
     let s:pkm.max_cols_lines = 2              " #2
     let s:pkm.keys = 'rbyo'

     function! s:pkm.OnKeySelect(winid, index) " #3
       echo self.items[a:index]
     endfunction

     call s:pkm.Load(s:colors)                 " #4
   endif

   call s:pkm.Open(s:options)                  " #5
   let s:pkm_id = s:pkm.pkm_id
 endfunction
