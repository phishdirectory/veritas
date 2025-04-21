AhoyEmail.default_options[:message] = true
AhoyEmail.subscribers << AhoyEmail::RedisSubscriber.new(redis: Redis.new)
AhoyEmail.api = true
