require 'sinatra'
require 'redis'

module Sger
	class Application < Sinatra::Application

		PAGE_SIZE = 3

		get %r{/$|/(\d+)$} do |page|
			
			page = (page || 1).to_i
			start_index = (page - 1) * PAGE_SIZE
			total_pages = (Sger.redis.zcard('sorted-posts').to_f / PAGE_SIZE.to_f).ceil.to_i

			keys = redis.zrevrange('sorted-posts', start_index, start_index + PAGE_SIZE - 1)
			posts = redis.hmget('posts', *keys).map { |s| MultiJson.load(s) }

			erb :index, locals: { posts: posts, page: page, total_pages: total_pages, window: 2 }
		end

		get %r{/([\w\d\-]+)$} do |key|
			post = redis.hget('posts', key)
			return erb :not_found unless post && post.length > 0

			erb :post, locals: { post: MultiJson.load(post) }
		end

		private
		def redis
			Sger.redis
		end
	end
end