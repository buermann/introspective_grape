require 'pundit'
module ErrorHandlers
  def self.included(m)
    m.rescue_from ActiveRecord::RecordInvalid do |e|
      error! e.record.errors.to_a.uniq.join(', '), 400
    end

    m.rescue_from Grape::Exceptions::ValidationErrors do |e|
      error! e.message, 400
    end

    m.rescue_from ActiveRecord::RecordNotFound do |e|
      error! "Record not found! #{e.message}", 404
    end

    m.rescue_from ActiveRecord::InvalidForeignKey do |e|
      error! "Join record not found! #{e.message}", 404
    end

    m.rescue_from Pundit::NotAuthorizedError do
      error! "Forbidden", 403
    end

    m.rescue_from Pundit::NotDefinedError do
      error! "Policy not implemented", 501
    end
  end
end
