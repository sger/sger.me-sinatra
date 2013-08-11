require 'date'
require 'redcarpet'
require 'safe_yaml'

desc "Import posts from GitHub"

task :clean do
	redis.flushdb
	`rm -rf tmp`
end

task :import do
	unless File.exists?('tmp/repo')
		puts 'Cloning posts'
		`git clone https://github.com/sger/content_blog.git  tmp/repo`
	else
		puts 'Updating posts'
		`cd tmp/repo && git pull origin master`
	end

	Dir['tmp/repo/posts/*.markdown'].each do |path|
		matches = path.match(/\/(\d{4})-(\d{2})-(\d{2})-([\w\-]+)\.markdown$/)
		key = matches[4]
		next if redis.hexists('posts', key)

		contents = File.open(path).read

		meta = {
			key: key,
			title: key.capitalize,
			published_at: Date.new(matches[1].to_i, matches[2].to_i, matches[3].to_i).to_time.utc.to_i,
			type: 'post'
		}

		if result = contents.match(/\A(---\s*\n.*?\n?)^(---\s*$\n?)/m)
			contents = contents[(result[0].length)...(contents.length)]
			#meta.merge!(YAML.safe_load(result[0]))
			meta.merge!(YAML.load(result[0], :safe => false))
		end

		meta[:html] = markdown(contents)

		redis.hset('posts', key, MultiJson.dump(meta))
		redis.zadd('sorted-posts', meta[:published_at], key)

		puts "post #{key}"
	end

	puts 'Import complete!!!'
end

def redis
	Sger.redis
end

def markdown(text)
	return '' unless text and text.length > 0

	options = {
		no_intra_emphasis: true,
		tables: true,
		fenced_code_blocks: true,
		autolink: true,
		strikethrough: true,
		space_after_headers: true,
		superscript: true
	}

	markdown = Redcarpet::Markdown.new(Sger::MarkdownRenderer, options)
	markdown.render(text)
end