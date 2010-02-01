require 'rubygems'
require 'lib/gemfire-jruby'
require 'lib/example_cache_listener'
require 'date'

server = GemFireServer.new('localhost:10355')
server.addListener(ExampleCacheListener.new)
server.write(100, {'hello' => 'world', 'goodbye' => 'life'})

#client = GemFireClient.new('localhost:10355')
#client.addListener(MyListener.new)