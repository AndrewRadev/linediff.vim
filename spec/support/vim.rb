require 'json'

module Support
  module Vim
    def set_file_contents(string)
      write_file(filename, string)
      vim.edit!(filename)
    end

    def expect_file_contents(string)
      expect(IO.read(filename).chomp).to eq(string.chomp)
    end

    def wincmd(command)
      vim.command("wincmd #{command}")
    end

    def buffer_contents
      vim.echo(%<join(getbufline('%', 1, '$'), "\n")>) + "\n"
    end

    def tabpage_buflist
      JSON.parse(vim.echo(%<tabpagebuflist()>))
    end
  end
end
