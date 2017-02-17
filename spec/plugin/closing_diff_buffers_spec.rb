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
end
