module AsyncRequest
  class JobsController < ActionController::Base
    before_action :log_request

    def show
      job = Job.find_by(uid: params.require(:id))
      return head :not_found unless job.present?
      job.finished? ? render_finished_job(job) : render_pending(job)
    end

    private

    def render_pending(job)
      render json: { status: job.status }, status: :accepted
    end

    def render_finished_job(job)
      log_execution_time(job)
      render json: JSON.parse(job.response), status: job.status_code
    end

    def log_request
      Rails.logger.info do
        "Request for \"utility_code\": \"#{utility_code_header}\"\n" \
        "Request for \"channel\": \"#{channel_header}\"\n" \
        "Request for \"app_version\": \"#{app_version_header}\""
      end
    end

    def log_execution_time(job)
      Rails.logger.info do
        "Total job execution time: #{job.execution_time}ms"
      end
    end

    def utility_code_header
      @utility_code_header ||= request.headers['Utility-ID']
    end

    def channel_header
      @channel_header ||= request.headers['Channel']
    end

    def app_version_header
      @app_version_header ||= request.headers['APP-VERSION']
    end
  end
end
