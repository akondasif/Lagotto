require 'custom_error'
require 'timeout'

class SourceJob < ActiveJob::Base
  # include HTTP request helpers
  include Networkable

  # include CouchDB helpers
  include Couchable

  include CustomError

  queue_as :default

  rescue_from StandardError do |exception|
    return nil if exception.class.to_s == "CustomError::SourceInactiveError"

    rs_ids, source = self.arguments
    RetrievalStatus.where("id in (?)", rs_ids).update_all(queued_at: nil)

    Alert.create(exception: exception,
                 class_name: exception.class.to_s,
                 message: "Rescued #{exception.message}",
                 source_id: source.id)
  end

  def perform(rs_ids, source)
    # check for failed queries
    source.work_after_failures_check
    fail SourceInactiveError, "#{source.display_name} is not in working state" unless source.working?

    rs_ids.each do |rs_id|
      # check for rate-limiting
      source.work_after_rate_limiting_check
      fail SourceInactiveError, "#{source.display_name} is not in working state" unless source.working?

      # observe rate-limiting settings
      sleep source.wait_time

      rs = RetrievalStatus.find(rs_id)

      # store API response result and duration in api_responses table
      response = { work_id: rs.work_id, source_id: rs.source_id, retrieval_status_id: rs_id }
      ActiveSupport::Notifications.instrument("api_response.get") do |payload|
        response.merge!(rs.perform_get_data)
        payload.merge!(response)
      end
    end
  end

  after_perform do |job|
    rs_ids, source = job.arguments
    RetrievalStatus.where("id in (?)", rs_ids).update_all(queued_at: nil)
    source.wait_after_check
  end
end
