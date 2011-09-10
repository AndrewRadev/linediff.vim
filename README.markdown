The linediff plugin provides a simple command, `:Linediff`, which is used to
diff two separate blocks of text.

A simple example:

    def one
      two
    end

    def two
      three
    end

If we mark the first three lines, starting from `def one`, in visual mode, and
execute the `:Linediff` command, the signs `1-` will be placed at the start
and at the end of the visual mode's range. Doing the same thing on the bottom
half of the code, starting from `def two`, will result in the signs `2-`
placed there. After that, a new tab will be opened with the two blocks of code in
vertical splits, diffed against each other.

The two buffers are temporary, but when any one of them is saved, its original
buffer is updated. Note that this does not **save** the original buffer, just
performs the change. Saving is something you should do later.

Executing the command `:LinediffReset` will delete the temporary buffers and
remove the signs.

Executing a new `:Linediff` will do the same as `:LinediffReset`, but will also
initiate a new diff process.

**Note that you shouldn't linediff two pieces of text that overlap**. Not that
anything horribly bad will happen, it just won't work as you'd hope to. I
don't feel like it's a very important use case, but if someone requests
sensible behaviour in that case, I should be able to get it working.
