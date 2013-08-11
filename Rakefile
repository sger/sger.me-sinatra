require 'rubygems'
require 'bundler'
Bundler.require

$LOAD_PATH.unshift 'lib'
require 'sger'

Dir.glob('lib/tasks/*.rake').each do |task|
	import task
end