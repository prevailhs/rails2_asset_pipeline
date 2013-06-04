require 'rails2_asset_pipeline/version'
require 'sprockets'

module Rails2AssetPipeline
  STATIC_ENVIRONMENTS = ["production", "staging"]

  class << self
    attr_accessor :static_environments, :dynamic_assets_available, :manifest
    # Expose settings for the sprockets task
    attr_accessor :output, :assets, :log_level, :keep
  end

  def self.static_environments
    @static_environments ||= STATIC_ENVIRONMENTS
  end

  # Provide defaults for sprockets task that matches legacy
  def self.output
    @output ||= "./public/assets"
  end

  def self.assets
    @assets ||= env.paths.map{|p| Dir["#{p.sub(Rails.root.to_s,"")}/**/*"] }.flatten
  end

  def self.log_level
    @log_level ||= Logger::ERROR
  end

  def self.keep
    @keep ||= 2
  end

  def self.env
    @env || setup
  end

  def self.setup(&block)
    # Only create and initialize the environment's paths once
    unless @env
      @env = Sprockets::Environment.new
      Dir[Rails.root.join("app", "assets", "*")].each do |folder|
        @env.append_path folder
      end
    end
    # TODO vendor + lib
    if block_given?
      args = [@env]
      # Yield self for configuration if the callee supports that
      args << self if block.arity > 1
      yield *args
    end
    @env
  end

  def self.config_ru
    lambda do
      unless Rails2AssetPipeline.static_environments.include?(Rails.env)
        Rails2AssetPipeline.dynamic_assets_available = true
        map '/assets' do
          run Rails2AssetPipeline.env
        end
      end
    end
  end

  def self.static?
    not Rails2AssetPipeline.dynamic_assets_available or Rails2AssetPipeline::static_environments.include?(Rails.env)
  end

  def self.with_dynamic_assets_available(value)
    old = dynamic_assets_available
    self.dynamic_assets_available = value
    yield
  ensure
    self.dynamic_assets_available = old
  end

  def self.manifest
    @manifest ||= "#{Rails.root}/public/assets/manifest.json"
  end

  def self.warn_user_about_misconfiguration!
    return unless Rails2AssetPipeline.static?
    return if @manifest_exists ||= File.exist?(manifest)

    config = "config.ru.example"
    if File.exist?(config) and File.read(config).include?("Rails2AssetPipeline.config_ru")
      raise "No dynamic assets available and no #{manifest} found, run `rake assets:precompile` for static assets or `cp #{config} config.ru` for dynamic assets"
    else
      raise "No dynamic assets available and no #{manifest} found, run `rake assets:precompile` for static assets or read https://github.com/grosser/rails2_asset_pipeline#dynamic-assets-for-development for instructions on dynamic assets"
    end
  end
  
  def self.find_asset(asset)
    warn_user_about_misconfiguration!

    asset_with_id = if static?
      @sprockets_manifest ||= Sprockets::Manifest.new(env, manifest)
      @sprockets_manifest.assets[asset]
    else
      data = env[asset]
      data ? "#{asset}?#{data.mtime.to_i}" : nil
    end

    asset_with_id ? "/assets/#{asset_with_id}" : nil
  end
end
