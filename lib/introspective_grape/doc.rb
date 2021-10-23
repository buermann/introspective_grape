module IntrospectiveGrape
  module Doc
    def index_documentation(name=nil)
      "returns list of all #{name}"
    end

    def show_documentation(name=nil)
      "returns details on a #{name}"
    end

    def create_documentation(name=nil)
      "creates a new #{name} record"
    end

    def update_documentation(name=nil)
      "updates the details of a #{name}"
    end

    def destroy_documentation(name=nil)
      "destroys the details of a #{name}"
    end
  end
end
