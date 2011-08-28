" Constructs a Differ object that is still unbound. To initialize the object
" with data, `Init(from, to)` needs to be invoked on that object.
function! linediff#BlankDiffer(sign_name, sign_number)
  let differ = {
        \ 'bufno':       -1,
        \ 'filetype':    '',
        \ 'from':        -1,
        \ 'to':          -1,
        \ 'sign_name':   a:sign_name,
        \ 'sign_number': a:sign_number,
        \ 'sign_text':   a:sign_number.'-',
        \ 'is_blank':    1,
        \
        \ 'Init':                 function('linediff#Init'),
        \ 'IsBlank':              function('linediff#IsBlank'),
        \ 'Reset':                function('linediff#Reset'),
        \ 'Lines':                function('linediff#Lines'),
        \ 'SetupDiffBuffer':      function('linediff#SetupDiffBuffer'),
        \ 'UpdateOriginalBuffer': function('linediff#UpdateOriginalBuffer'),
        \ }

  exe "sign define ".differ.sign_name." text=".differ.sign_text." texthl=Search"

  return differ
endfunction

" Sets up the Differ with data from the argument list and from the current
" file.
function! linediff#Init(from, to) dict
  let self.bufno    = bufnr('%')
  let self.filetype = &filetype
  let self.from     = a:from
  let self.to       = a:to

  exe printf("sign place %d1 name=%s line=%d buffer=%d", self.sign_number, self.sign_name, self.from, self.bufno)
  exe printf("sign place %d2 name=%s line=%d buffer=%d", self.sign_number, self.sign_name, self.to,   self.bufno)

  let self.is_blank = 0
endfunction

" Returns true if the differ is blank, which means not initialized with data.
function! linediff#IsBlank() dict
  return self.is_blank
endfunction

" Resets the differ to the blank state. Invoke `Init(from, to)` on it later to
" make it usable again.
function! linediff#Reset() dict
  let self.bufno    = -1
  let self.filetype = ''
  let self.from     = -1
  let self.to       = -1

  exe "sign unplace ".self.sign_number."1"
  exe "sign unplace ".self.sign_number."2"

  let self.is_blank = 1
endfunction

" Extracts the relevant lines from the original buffer and returns them as a
" list.
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

  let b:differ = self

  autocmd BufWrite <buffer> call b:differ.UpdateOriginalBuffer()
endfunction

" Updates the original buffer after saving the temporary one.
"
" TODO Currently, this only takes care of simple changes, doesn't consider
" changes in the number of lines at all, and empties the diff buffer for some
" reason.
function! linediff#UpdateOriginalBuffer() dict
  let lines           = getbufline('%', 0, '$')
  let diff_buffer     = bufnr('%')
  let original_buffer = self.bufno

  exe original_buffer."buffer"
  let pos = getpos('.')
  call cursor(self.from, 1)
  exe "normal! ".(self.to - self.from + 1)."dd"
  call append(self.from - 1, lines)
  call setpos('.', pos)

  exe diff_buffer."buffer"
  call self.SetupDiffBuffer()
endfunction
