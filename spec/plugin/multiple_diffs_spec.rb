require 'spec_helper'

describe "Multiple diffs" do
  let(:filename) { 'test.txt' }

  specify "with :LinediffAdd and :LinediffShow" do
    set_file_contents <<~EOF
      one
      two
      three
    EOF

    vim.command '1,1LinediffAdd'
    vim.command '2,2LinediffAdd'
    vim.command '3,3LinediffAdd'
    vim.command 'LinediffShow'

    expect(tabpage_buflist.length).to eq 3
  end

  specify "with :LinediffAdd and :LinediffLast" do
    set_file_contents <<~EOF
      one
      two
      three
    EOF

    vim.command '1,1LinediffAdd'
    vim.command '2,2LinediffAdd'
    vim.command '3,3LinediffLast'

    expect(tabpage_buflist.length).to eq 3
  end

  specify "with :Linediff, :LinediffAdd and :LinediffLast" do
    set_file_contents <<~EOF
      one
      two
      three
    EOF

    vim.command '1,1Linediff'
    vim.command '2,2LinediffAdd'
    vim.command '3,3LinediffLast'

    expect(tabpage_buflist.length).to eq 3
  end
end
