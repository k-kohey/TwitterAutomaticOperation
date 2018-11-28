require 'twitter'
require 'dotenv'

class TwitterClient
	def initialize
    	@myName = ENV['MY_NAME']
    	@client = Twitter::REST::Client.new do |config|
		  config.consumer_key        = ENV['MY_CONSUMER_KEY']
		  config.consumer_secret     = ENV['MY_CONSUMER_SECRET']
		  config.access_token        = ENV['MY_ACCESS_TOKEN']
		  config.access_token_secret = ENV['MY_ACCESS_TOKEN_SECRET']
		end
  	end

	def follow()
		@client.search(ENV['FOLLOW_KEYWORD_1'], lang: "ja").take(5).each do |tweet|
		   @client.follow(tweet.user.id)
		   p "#{tweet.user.id} をフォローした"
		end

		@client.search(ENV['FOLLOW_KEYWORD_2']).take(5).each do |tweet|
		   @client.follow(tweet.user.id)
		   p "#{tweet.user.id} をフォローした"
		end

		@client.search(ENV['FOLLOW_KEYWORD_3'], lang: "ja").take(5).each do |tweet|
		   @client.follow(tweet.user.id)
		   p "#{tweet.user.id} をフォローした"
		end
	end

	def favorite()
		@client.search("to: #{@myName}").take(15).each do |tweet|
			@client.favorite(tweet.id)
			p "#{tweet.user.screen_name}さんにファボ"
		end

		@client.search(ENV['FAV_KEYWORD_1']).take(15).each do |tweet|
			@client.favorite(tweet.id)
			p "#{tweet.user.screen_name}さんにファボ"
		end
		
		@client.search(ENV['FAV_KEYWORD_2']).take(15).each do |tweet|
			@client.favorite(tweet.id)
			p "#{tweet.user.screen_name}さんにファボ"
		end
	end

	def followBack()
		follower_ids = []
		@client.follower_ids(myName).each do |id|
		  follower_ids.push(id)
		end
		
		friend_ids = []
		@client.friend_ids(myName).each do |id|
		  friend_ids.push(id)
		end
		follow_target_user_ids = follower_ids - friend_ids
		if !follow_target_user_ids.empty?
			@client.follow(follower_ids - friend_ids)
			p "フォロバ完了"
		end
	end

	def self.remove()
		follower_ids = []
		@client.follower_ids(myName).each do |id|
		  follower_ids.push(id)
		end
		
		friend_ids = []
		@client.friend_ids(myName).each do |id|
		  friend_ids.push(id)
		end
		remove_target_user_ids = friend_ids - follower_ids
		
		if !remove_target_user_ids.empty? 
			@client.unfollow(friend_ids - follower_ids)
			p "リムーブ完了"
		end
	end
end

class Stream
	def initialize()
		Dotenv.load ".env"
	end

	def start()
		loop_count = 0
		client = TwitterClient.new()
		while true 
			begin
				client.follow()
				elapsed_minutes = loop_count * 15
				next if elapsed_minutes == 0
				#2時間に一度
				if elapsed_minutes % (2 * 60) == 0
					client.favorite()
					client.followBack()					
				# 1日に一回はリムーブ
				elsif elapsed_minutes % (24 * 60 * 1) == 0
					client.remove()
					# いつかオーバーフローしちゃうので初期化．
					loop_count = 0
				end				
			rescue Twitter::Error::TooManyRequests => error
				p "フォローしすぎ😭 #{error.rate_limit.reset_in / 60}分待つよ"
				sleep error.rate_limit.reset_in
				retry
			end
		loop_count = loop_count + 1
		end
	end
end


stream = Stream.new()
stream.start()

