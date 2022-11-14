module AsyncRequest
  module ApplicationHelper
    def execute_async(worker_class, *worker_params)
      raise ArgumentError if worker_class.nil?
      @worker_params = worker_params
      @worker_class = worker_class
      job = Job.create!(
        worker: worker_class,
        params: set_worker_params,
        status: Job.statuses[:waiting],
        uid: SecureRandom.uuid
      )
      JobProcessor.perform_async(job.id, job.worker)
      job.uid
    end

    def set_extra_data(new_data)
      @extra_data = new_data
    end

    def add_extra_data(new_data)
      extra_data.merge!(new_data)
    end

    private

    def extra_data
      @extra_data ||= {}
    end

    def set_worker_params 
      return @worker_params unless send_extra_data?
      params_and_extra_data
    end

    def send_extra_data?
      !extra_data.empty? && @worker_class.respond_to?(:handle_extra_data?) && @worker_class.handle_extra_data?
    end

    def params_and_extra_data
      @worker_params.push(extra_data.merge(extra_data: true))
    end
  end
end
