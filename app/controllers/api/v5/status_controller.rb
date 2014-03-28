# $HeadURL$
# $Id$
#
# Copyright (c) 2009-2012 by Public Library of Science, a non-profit corporation
# http://www.plos.org/
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class Api::V5::StatusController < Api::V5::BaseController

  load_and_authorize_resource :alert, :parent => false

  def index
    @status = OpenStruct.new({ articles_count: Article.count,
                               events_count: RetrievalStatus.joins(:source).where("state > ?", 0).where("name != ?", "relativemetric").sum(:event_count),
                               sources_disabled_count: Source.where("state = ?", 1).count,
                               alerts_last_day_count: Alert.total_errors(1).count,
                               workers_count: Worker.count,
                               delayed_jobs_active_count: DelayedJob.count,
                               responses_count: ApiResponse.total(1).count,
                               requests_count: ApiRequest.where("created_at > ?", Time.zone.now - 1.day).count,
                               users_count: User.count,
                               version: VERSION,
                               couchdb_size: RetrievalStatus.new.get_alm_database["disk_size"] || 0,
                               mysql_size: RetrievalHistory.table_status["data_length"] || 0,
                               update_date: Status.update_date,
                               cache_key: Status.update_date })
  end
end