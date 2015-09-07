require "auto_reload/version"

module AutoReload
  class << self
     attr_accessor :_enable_auto_reload, :_autoreload_gems


    def auto_reload_gems *gems
      return @_enable_auto_reload = false if gems.first == false

      @_enable_auto_reload = true
      @_autoreload_gems = ((@_autoreload_gems || [] ) + gems).uniq
    end

    def reload_gems?
      Rails.env.development? && !!AutoReload._enable_auto_reload && AutoReload._autoreload_gems.any?
    end
  end

  module ActionControllerBaseMethods

    def self.included(base)
      with_options if: :reload_libs? do
        base.before_action :reload_gems
        base.before_action :reload_rails_admin_config
        base.before_action :reload_libs
        base.before_action :reload_initializers
      end
    end

    def reload_gems
      #RequireReloader.send(:local_gems)
    end

    def reload_lib
      files_to_reload = []
      ["lib/**/*.rb"].each{|p| files_to_reload += Dir[Rails.root.join(p)] }

      reload_files(files_to_reload)
    end

    def reload_files(files_to_reload)
      files_to_reload.each do |f|
        begin
          #require_dependency f
          load f
        rescue RuntimeError
        end
      end
    end

    def reload_libs
      if Rails.env.development?

        files_to_reload = []
        ["lib/**/*.rb", "config/initializers/**/*.rb"].each{|p| files_to_reload += Dir[Rails.root.join(p)] }

        reload_files(files_to_reload)

      end
    end

    def reload_initializers
      if Rails.env.development?

        files_to_reload = []
        [ "config/initializers/**/*.rb"].each{|p| files_to_reload += Dir[Rails.root.join(p)] }

        reload_files(files_to_reload)
      end
    end


    def reload_libs?
      AutoReload.reload_gems?
    end


    def reload_rails_admin_config
      RailsAdmin::Config.reset
      RailsAdmin::Config.models.each do |m|
        RailsAdmin::Config.reset_model(m.abstract_model.model_name)
      end

      #load("#{Rails.root}/config/initializers/rails_admin.rb")
    end

    def reload_rails_admin_plugins
      # helper = RequireReloader::Helper.new
      # gem_name = "rails_admin"
      # helper.remove_gem_module_if_defined(gem_name)
      # require gem_name
    end

    def json_request?
      request.format.json?
    end
  end
end



ActionController::Base.send :include, AutoReload::ActionControllerBaseMethods


Rails::Application.module_eval do
  def reload_local_gems
    if AutoReload.reload_gems?
      Rails.application.config.eager_load = true
      #RequireReloader.watch("rails_admin")
      #RequireReloader.watch_local_gems!


      watch_gems = AutoReload._autoreload_gems

      watch_gems.each do |gem_name|
        RequireReloader.watch(gem_name)
      end
    end
  end
end