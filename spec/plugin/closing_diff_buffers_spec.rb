require 'spec_helper'

describe "Basic" do
  let(:filename) { 'test.rb' }

  before do
    set_file_contents <<~EOF
      first
      second
    EOF

    vim.command '1,1Linediff'
    vim.command '2,2Linediff'
  end

  specify "original buffer updates upon closing the differ tab" do
    vim.normal 'A (changed)'
    vim.write
    wincmd 'w'
    vim.normal 'A (changed)'
    vim.write

    vim.command 'tabclose'

    expect(buffer_contents).to eq <<~EOF
      first (changed)
      second (changed)
    EOF
  end

  specify "original buffer updates upon closing one differ" do
    vim.normal 'A (changed)'
    vim.write
    wincmd 'w'
    vim.normal 'A (changed)'
    vim.write

    vim.command 'quit'

    expect(buffer_contents).to eq <<~EOF
      first (changed)
      second (changed)
    EOF
  end

  specify "it's possible to close everything at once" do
    vim.normal 'A (changed)'
    vim.write
    wincmd 'w'
    vim.normal 'A (changed)'
    vim.write

    # write the original buffer after it's been updated by the diff buffers
    vim.command 'wall'

    vim.command 'tabnew'
    vim.command 'tabonly'

    expect_file_contents(<<~EOF)
      first (changed)
      second (changed)
    EOF
  end
end
