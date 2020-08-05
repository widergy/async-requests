module AsyncRequest
  class JobsController < ActionController::Base
    before_action :log_request

    def show
      job = Job.find_by(uid: params[:id])
      return head :not_found unless job.present?
      job.finished? ? render_finished_job(job) : render_pending(job)
    end

    private

    def render_pending(job)
      render json: { status: job.status }, status: :accepted
    end

    def render_finished_job(job)
      render json: JSON.parse(job.response), status: job.status_code
    end

    def log_request
      Rails.logger.info do
        "Request for Utility-ID: #{utility_code_header} and Channel: #{channel_header}"
      end
    end

    def utility_code_header
      @utility_code_header ||= request.headers['Utility-ID']
    end

    def channel_header
      @channel_header ||= request.headers['Channel']
    end
  end
end
