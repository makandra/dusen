module Rails
  class Railtie < Rails::Railtie
    railtie_name :dusen

    rake_tasks do
      load "tasks/my_plugin.rake"
    end
  end
end