module Tabloid
  def self.cache_engine=(engine)
    @engine = engine
  end

  def self.cache_engine
    @engine
  end

  def self.cache_enabled?
    !@engine.nil?
  end

  def self.cache_connection_options=(options)
    @cache_connection_options = options
  end
  def self.cache_connection_options
    @cache_connection_options || {}
  end
end