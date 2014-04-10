#
# Copyright (c) 2009-2013 by Public Library of Science, a non-profit corporation
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

class RelativeMetric < Source

  def get_data(article, options={})

    # Check that article has DOI
    return { :events => [], :event_count => nil } if article.doi.blank?

    if article.is_publisher?

      events = get_relative_metric_data(article)

      if events.blank?
        return nil
      else
        total = 0
        events[:subject_areas].each do | subject_area |
          total += subject_area[:average_usage].reduce(:+)
        end

        event_metrics = { :pdf => nil,
                          :html => nil,
                          :shares => nil,
                          :groups => nil,
                          :comments => nil,
                          :likes => nil,
                          :citations => nil,
                          :total => total }

        { :events => events,
          :event_count => total,
          :event_metrics => event_metrics }
      end
    else
      { :events => [], :event_count => nil }
    end
  end


  def get_relative_metric_data(article)
    events = {}

    year = article.published_on.year

    events[:start_date] = "#{year}-01-01T00:00:00Z"
    events[:end_date] = Date.civil(year, -1, -1).strftime("%Y-%m-%dT00:00:00Z")

    query_url = get_query_url(article)
    data = get_json(query_url)

    if data.nil?
      return nil
    else
      events[:subject_areas] = data["rows"].map { |row| { :subject_area => row["value"]["subject_area"], :average_usage => row["value"]["data"] } }
    end

    return events
  end

  def get_config_fields
    [{ :field_name => "url", :field_type => "text_area", :size => "90x2"}]
  end

  def rate_limiting
    config.rate_limiting || 50000
  end

  def workers
    config.workers || 5
  end
end