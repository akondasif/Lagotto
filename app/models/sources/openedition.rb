# encoding: UTF-8

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

class Openedition < Source

  validates_not_blank(:url)

  def get_data(article, options={})

    return  { :events => [], :event_count => nil } if article.doi.blank?

    query_url = get_query_url(article)
    result = get_xml(query_url, options)

    # Check that Openedition has returned something, otherwise an error must have occured
    return nil if result.nil?

    events = []
    result.remove_namespaces!
    result.xpath("//item").each do |item|
      event = Hash.from_xml(item.to_s)
      event = event['item']
      events << { :event => event, :event_url => event['link'] }
    end

    events_url = "http://search.openedition.org/index.php?op%5B%5D=AND&q%5B%5D=#{article.doi_escaped}&field%5B%5D=All&pf=Hypotheses.org"
    event_metrics = { :pdf => nil,
                      :html => nil,
                      :shares => nil,
                      :groups => nil,
                      :comments => nil,
                      :likes => nil,
                      :citations => events.length,
                      :total => events.length }

    { :events => events,
      :events_url => events_url,
      :event_count => events.length,
      :event_metrics => event_metrics,
      :attachment => events.empty? ? nil : { :filename => "events.xml", :content_type => "text\/xml", :data => result.to_s }}
  end

  def get_query_url(article)
    url % { :query_url => article.doi_escaped }
  end

  def get_config_fields
    [{:field_name => "url", :field_type => "text_area", :size => "90x2"}]
  end

  def url
    config.url
  end

  def url=(value)
    config.url = value
  end

  def staleness_year
    config.staleness_year || 1.month
  end

  def rate_limiting
    config.rate_limiting || 1000
  end

end