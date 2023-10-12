module AsyncRequest
  class Job < ActiveRecord::Base
    serialize :params, Array
    enum status: { waiting: 0, processing: 1, processed: 2, failed: 3 }

    def finished?
      processed? || failed?
    end

    def processing!
      Rails.logger.info("Processing #{worker} job with id=#{uid}")
      super
    end

    def successfully_processed!(response, status_code)
      Rails.logger.info("Processing finished successfully for #{worker} job with id=#{uid}")
      update_attributes!(
        status: :processed,
        status_code: map_status_code(status_code),
        response: response.to_json
      )
    end

    def finished_with_errors!(error)
      log_message = "Processing failed for #{worker} job with id=#{uid}"
      Rails.logger.info(log_message)
      Rails.logger.error "#{error.inspect} \n #{error.backtrace.join("\n")}"
      Rollbar.error(error, log_message, params: filtered_params(params).inspect)
      update_attributes!(status: :failed, status_code: 500, response: error_response(error))
    end

    # This method will return the job execution time in milliseconds
    def execution_time
      (1000 * (updated_at - created_at)).to_i
    end

    private

    def map_status_code(status_code)
      return Rack::Utils::SYMBOL_TO_STATUS_CODE[status_code] if status_code.is_a?(Symbol)
      status_code.to_i
    end

    def filtered_params(params)
      params.is_a?(Array) ? filter_array(params) : single_filter(params)
    end

    def single_filter(params)
      parameter_filter.filter({"params" => params.compact})
    end

    def parameter_filter(params)
      @filter ||= ActionDispatch::Http::ParameterFilter.new(Rails.application.config.filter_parameters)
    end

    def filter_array(params)
      params.map { |element| 
        filtered_params(element)["params"]
      }
    end

    def error_response(error)
      {
        errors: [
          {
            status: 500,
            code: :internal_server_error,
            message: 'Algo salió mal. Por favor intente nuevamente más tarde.',
            meta: error.inspect
          }
        ]
      }.to_json
    end
  end
end
