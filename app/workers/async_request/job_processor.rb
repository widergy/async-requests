module AsyncRequest
  class JobProcessor
    include Sidekiq::Worker
    sidekiq_options queue: AsyncRequest.config[:queue], retry: AsyncRequest.config[:retry]

    def perform(id, _worker_class)
      job = Job.find(id)
      job.processing!
      begin
        status, response = job.worker.constantize.new.execute(*job.params)
        job.successfully_processed!(response, status)
      rescue StandardError => e
        job.finished_with_errors! e
      ensure
        log_to_prometheus(job)
      end
    end

    private

    def log_to_prometheus(job)
      prometheus_data = job.params.last.try(:[], :prometheus_data)
      return unless prometheus_data.present?
      
      channel = job.params.last.try(:[], :channel)

      Prometheus::CustomMetrics.http_request_outcome_counter_increase(prometheus_data, channel,
                                                                      job.status_code)
    end
  end
end
