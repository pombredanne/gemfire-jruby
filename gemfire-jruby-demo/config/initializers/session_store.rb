require 'rubygems'
require 'gemfire-jruby'
# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_gemfire-jruby-demo_session',
  :secret      => '717e04f621e7d080823adccb684eaa554ce3a5a88d54529f251bb850e4448064345a5ee51363c7c3ac1f08e794186cc704a32ef00f5a661571e3a602b28b99af'
}

ActionController::Base.cache_store = ActiveSupport::Cache::GemFire.getInstance({})

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
#ActionController::Base.session_store = :active_record_store
