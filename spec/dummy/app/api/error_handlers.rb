require 'pundit'
module ErrorHandlers
  def self.included(m)
    m.rescue_from ActiveRecord::RecordInvalid do |e|
      error_response message: e.record.errors.to_a.uniq.join(', '), status: 400
    end

    m.rescue_from Grape::Exceptions::ValidationErrors do |e|
      error_response message: e.message, status: 400
    end

    m.rescue_from ActiveRecord::RecordNotFound do |e|
      error_response message: "Record not found! #{e.message}", status: 404
    end

    m.rescue_from ActiveRecord::InvalidForeignKey do |e|
      error_response message: "Join record not found! #{e.message}", status: 404
    end

    m.rescue_from Pundit::NotAuthorizedError do
      error_response message: "Forbidden", status: 403 
    end

    m.rescue_from Pundit::NotDefinedError do
      error_response message: "Policy not implemented", status: 501 
    end
  end
end
