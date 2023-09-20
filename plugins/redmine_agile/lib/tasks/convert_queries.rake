namespace :redmine do
  namespace :agile do

    desc <<-END_DESC
    Convert old-format AgilrQueries to current serialize data

Example:
  rake redmine:agile:convert_queries RAILS_ENV="production"
END_DESC

    task convert_queries: :environment do
      class OldAgileQuery < ActiveRecord::Base
        self.table_name = 'queries'
        self.ignored_columns = %w(type)
      end

      OldAgileQuery.where("options LIKE '%ActionController::Parameters%'").find_each do |query|
        options = YAML.respond_to?(:unsafe_load) ? YAML.unsafe_load(query.options) : YAML.load(query.options)
        options[:wp] = options[:wp].permit!.to_h
        query.update_column(:options, options.to_yaml)
      end
    end
  end
end
