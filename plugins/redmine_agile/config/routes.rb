# This file is a part of Redmin Agile (redmine_agile) plugin,
# Agile board plugin for redmine
#
# Copyright (C) 2011-2023 RedmineUP
# http://www.redmineup.com/
#
# redmine_agile is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_agile is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_agile.  If not, see <http://www.gnu.org/licenses/>.

# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :projects do
  resources :agile_queries, only: [:new, :create]
  resources :agile_charts_queries, only: [:new, :create]
  resources :agile_version_queries, only: [:new, :create, :edit, :update, :destroy]
  resources :agile_sprint_queries, only: [:new, :create, :edit, :update, :destroy]
  resources :agile_versions, only: [:index] do
    collection do
      get 'sprints'
      get 'load_more'
      get 'autocomplete'
    end
  end

  resources :agile_sprints
  get "get_story_points", :to => "agile_sprints#get_story_points"
end

resources :issues do
  get "done_ratio", :to => "agile_journal_details#done_ratio"
  get "status", :to => "agile_journal_details#status"
  get "assignee", :to => "agile_journal_details#assignee"
  member do
    get "agile_data", :to => "agile_boards#agile_data"
  end
end

resources :agile_queries
resources :agile_charts_queries, except: [:index, :show]
get '/agile_colors/:object_type', :to => "agile_colors#index", :as => "agile_colors"
put '/agile_colors/:object_type', :to => "agile_colors#update", :as => "update_agile_colors"

get '/projects/:project_id/agile/charts', :to => "agile_charts#show", :as => "project_agile_charts"
get '/agile/charts/', :to => "agile_charts#show", :as => "agile_charts"
get '/agile/charts/render_chart', :to => "agile_charts#render_chart"
get '/agile/charts/select_version_chart', :to => "agile_charts#select_version_chart"
get '/projects/:project_id/agile/board', :to => 'agile_boards#index'
get '/agile/board', :to => 'agile_boards#index'
put '/agile/board', :to => 'agile_boards#update', :as => 'update_agile_board'
get '/agile/board/backlog_load_more', :to => 'agile_boards#backlog_load_more', as: 'backlog_load_more_agile_boards'
get '/agile/board/backlog_autocomplete', :to => 'agile_boards#backlog_autocomplete', as: 'backlog_autocomplete_agile_boards'
get '/agile/issue_tooltip', :to => 'agile_boards#issue_tooltip', :as => 'issue_tooltip'
get '/agile/inline_comment', :to => 'agile_boards#inline_comment', :as => 'agile_inline_comment'
post 'projects/:project_id/agile/create_issue', :to => 'agile_boards#create_issue', :as => 'agile_create_issue'
get 'agile/issues/:id/edit', :to => 'agile_boards#edit_issue', :as => 'agile_edit_issue'
put 'agile/issues/:id/update', :to => 'agile_boards#update_issue', :as => 'agile_update_issue'
