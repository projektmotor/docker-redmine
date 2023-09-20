namespace :redmine do
  namespace :agile do
    desc <<-END_DESC
    Convert old-format Settings to current serialize data

Example:
rake redmine:agile:convert_settings RAILS_ENV="production"
END_DESC

    task convert_settings: :environment do
      class OldSetting < ActiveRecord::Base
        self.table_name = 'settings'
        self.ignored_columns = %w(type)
      end

      OldSetting.where("value LIKE '%ActionController::Parameters%'").find_each do |setting|
        value = YAML.respond_to?(:unsafe_load) ? YAML.unsafe_load(setting.value) : YAML.load(setting.value)
        value = value.permit!.to_h
        setting.update_column(:value, value.to_yaml)
      end
    end
  end
end
