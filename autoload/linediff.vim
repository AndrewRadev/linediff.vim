function! linediff#BlankBufferData()
  return {
        \ 'bufno':    -1,
        \ 'filetype': '',
        \ 'from':     -1,
        \ 'to':       -1,
        \
        \ 'is_blank': 1,
        \
        \ 'Init':    function('linediff#Init'),
        \ 'IsBlank': function('linediff#IsBlank'),
        \ 'Reset':   function('linediff#Reset')
        \ }
endfunction

function! linediff#Init(data) dict
  let self.bufno    = a:data.bufno
  let self.filetype = a:data.filetype
  let self.from     = a:data.from
  let self.to       = a:data.to

  let self.is_blank = 0
endfunction

function! linediff#IsBlank() dict
  return self.is_blank
endfunction

function! linediff#Reset() dict
  let self.bufno    = -1
  let self.filetype = ''
  let self.from     = -1
  let self.to       = -1

  let self.is_blank = 1
endfunction
