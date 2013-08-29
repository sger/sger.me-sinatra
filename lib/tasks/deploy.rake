desc 'Push to GitHub And Heroku'

task :deploy do
	unless `git status -s`.length == 0
    puts 'Commit any changes.'
    exit
  end

  	`git push origin master`
  	`git push heroku master`
end