# encoding: UTF-8
require 'rails2_asset_pipeline'
require 'rake/sprocketstask'

namespace :assets do
  load_tasks = lambda do
    namespace :r2ap do
      Rake::SprocketsTask.new do |t|
        t.environment = Rails2AssetPipeline.env
        t.output = Rails2AssetPipeline.output
        t.assets = Rails2AssetPipeline.assets
        t.log_level = Rails2AssetPipeline.log_level
        t.keep = Rails2AssetPipeline.keep
      end
    end
  end

  task :config do
    initializer = Rails.root.join("config/initializers/rails2_asset_pipeline.rb")
    load initializer if File.exist?(initializer)
  end

  desc "Compile all the assets"
  task :precompile => "assets:config" do
    load_tasks.call
    Rake::Task["r2ap:assets"].invoke
  end

  desc "Remove compiled assets"
  task :clean => "assets:config" do
    load_tasks.call
    Rake::Task["r2ap:clobber"].invoke
  end

  desc "Remove old assets"
  task :remove_old => "assets:config" do
    load_tasks.call
    Rake::Task["r2ap:clean"].invoke
  end

  desc "converts project from jammit based assets.yml"
  task :convert_jammit do
    require 'rails2_asset_pipeline/jammit_converter'
    Rails2AssetPipeline::JammitConverter.convert
  end
end
