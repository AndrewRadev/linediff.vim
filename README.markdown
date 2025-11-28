[![GitHub version](https://badge.fury.io/gh/andrewradev%2Flinediff.vim.svg)](https://badge.fury.io/gh/andrewradev%2Flinediff.vim)

The plugin provides a simple command, `:Linediff`, which is used to diff two separate blocks of text.

![Demo](http://i.andrewradev.com/24f5ad78d6deff0b2492dd011dbca7a9.gif)

A simple example:

``` ruby
def one
  two
end

def two
  three
end
```

If we mark the first three lines, starting from "def one", in visual mode, and execute the `:Linediff` command, the signs "1-" will be placed at the start and at the end of the visual mode's range. Doing the same thing on the bottom half of the code, starting from "def two", will result in the signs "2-" placed there. After that, a new tab will be opened with the two blocks of code in vertical splits, diffed against each other.

The two buffers are temporary, but when any one of them is saved, its original buffer is updated. Note that this doesn't save the original buffer, just performs the change. Saving is something you should do later.

Executing the command `:LinediffReset` will delete the temporary buffers and remove the signs. Executing a new `:Linediff` will do the same as `:LinediffReset`, but will also initiate a new diff process.

The statuslines of the two temporary buffers will be changed to contain:

- The original buffer
- The starting line of the selected segment
- The ending line of the selected segment

If you're using a custom statusline and it contains "%f" (the current file's name), that token will simply be substituted by the above data. Otherwise, the entire statusline will be set to a custom one.

If you'd rather the statusline is left untouched, you can set the `g:linediff_modify_statusline` setting to 0. You can still access the buffer description via `b:differ.description`.

If you'd like to do some additional setup on the buffers, you can hook into the `LinediffBufferReady` User autocommand. For instance, in order to stop the linediff with a `q`, try:

```vim
autocmd User LinediffBufferReady nnoremap <buffer> q :LinediffReset<cr>
```

### Diffing more than two areas

If you'd like to diff more than two areas of code, you can use the `:LinediffAdd` command after the first `:Linediff` to mark more areas. You can then call `:LinediffShow` to open the diff:

```vim
:1,2Linediff
:3,4LinediffAdd
:5,6LinediffAdd
:LinediffShow
```

This will diff the three specified areas. Alternatively, you can use the `:LinediffLast` command to add and show the differ. So, the above code is equivalent to:

```vim
:1,2Linediff
:3,4LinediffAdd
:5,6LinediffLast
```

Note that there's a hard limit of 8 diffs set by Vim, so you can't diff more areas than that.

### Diffing merges

If you have a merge conflict like this one:

``` ruby
def one
<<<<<<< main
  "first"
=======
  "second"
>>>>>>> branch
end
```

You can easily start a diff between the two variants of the code by executing the `:LinediffMerge` command. You can use the diffed buffers the same way, or, you can use `:LinediffPick` to choose one buffer whose contents will replace the entire merge conflict. This also works with three-way diffs:

``` ruby
def one
<<<<<<< master
  "first"
|||||||
  "second"
=======
  "third"
>>>>>>> branch
end
```

The statuslines of the diff buffers will hold the label of the merge parent for convenience. Also for convenience, executing `:LinediffPick` directly on the merge area will pick the area without going through the merge buffers first.

## Contributing

Pull requests are welcome, as long as they did not involve LLM usage. Be sure to abide by the [CODE_OF_CONDUCT.md](https://codeberg.org/AndrewRadev/python_tools.vim/blob/main/CODE_OF_CONDUCT.md) as well.
