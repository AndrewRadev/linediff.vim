" Constructs a buffer data object that is still unbound. To initialize the
" object with data, `Init(from, to)` needs to be invoked on that object.
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

" Sets up the buffer data object with data from the argument list and from the
" current file.
function! linediff#Init(from, to) dict
  let self.bufno    = bufnr('%')
  let self.filetype = &filetype
  let self.from     = a:from
  let self.to       = a:to

  let self.is_blank = 0
endfunction

" Returns true if the buffer data object is blank, which means not initialized
" with data.
function! linediff#IsBlank() dict
  return self.is_blank
endfunction

" Resets the buffer data object to the blank state. Invoke `Init(from, to)` on
" it later to make it usable again.
function! linediff#Reset() dict
  let self.bufno    = -1
  let self.filetype = ''
  let self.from     = -1
  let self.to       = -1

  let self.is_blank = 1
endfunction

" Extracts the relevant lines from the original buffer for this particular
" diff and returns them as a list.
function! linediff#Lines() dict
  return getbufline(self.bufno, self.from, self.to)
endfunction

" Sets up the temporary buffer's filetype and statusline.
"
" Attempts to leave the current statusline as it is, and simply add the
" relevant information in the place of the current filename. If that fails,
" replaces the whole statusline.
function! linediff#SetupDiffBuffer() dict
  let statusline = printf('[%s:%d-%d]', bufname(self.bufno), self.from, self.to)
  if &statusline =~ '%f'
    let statusline = substitute(&statusline, '%f', statusline, '')
  endif
  exe "setlocal statusline=" . escape(statusline, ' ')
  exe "set filetype=" . self.filetype
endfunction
