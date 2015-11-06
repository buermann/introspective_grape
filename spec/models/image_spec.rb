require 'rails_helper'
require 'paperclip/matchers'

RSpec.describe Image, type: :model do
  include Paperclip::Shoulda::Matchers

  it { should have_attached_file(:file) }
  it { should validate_attachment_content_type(:file).
        allowing('image/png', 'image/gif', 'image/jpeg')
  }
  it { should validate_attachment_size(:file).less_than(2.megabytes) }


end
