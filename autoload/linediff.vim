function! linediff#BlankBufferData()
  return {
        \ 'bufno':    -1,
        \ 'filetype': '',
        \ 'from':     -1,
        \ 'to':       -1,
        \
        \ 'is_blank': 1,
        \
        \ 'Init':            function('linediff#Init'),
        \ 'IsBlank':         function('linediff#IsBlank'),
        \ 'Reset':           function('linediff#Reset'),
        \ 'Lines':           function('linediff#Lines'),
        \ 'SetupDiffBuffer': function('linediff#SetupDiffBuffer'),
        \ }
endfunction

function! linediff#Init(from, to) dict
  let self.bufno    = bufnr('%')
  let self.filetype = &filetype
  let self.from     = a:from
  let self.to       = a:to

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

function! linediff#Lines() dict
  return getbufline(self.bufno, self.from, self.to)
endfunction

function! linediff#SetupDiffBuffer() dict
  let statusline = printf('[%s:%d-%d]', bufname(self.bufno), self.from, self.to)
  if &statusline =~ '%f'
    let statusline = substitute(&statusline, '%f', statusline, '')
  endif
  exe "setlocal statusline=" . escape(statusline, ' ')
  exe "set filetype=" . self.filetype
endfunction
