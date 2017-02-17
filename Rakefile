task :default do
  sh 'rspec spec'
end

desc "Prepare archive for deployment"
task :archive do
  sh 'zip -r ~/linediff.zip autoload/ doc/linediff.txt plugin/'
end
