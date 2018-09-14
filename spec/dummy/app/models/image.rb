require 'paperclip'
#require 'delayed_paperclip'
class Image < ActiveRecord::Base
  belongs_to :imageable, polymorphic: true

  has_attached_file :file, #styles: {medium: "300x300>", thumb: "100x100"},
    url: "/system/:imageable_type/:imageable_id/:id/:style/:filename"

  validates_attachment :file, content_type: {content_type: ["image/jpeg", "image/png", "image/gif"]}
  validates_attachment_size :file, :less_than => 2.megabytes

  def medium_url
    file.url(:medium)
  end
  #process_in_background :file, processing_image_url: 'empty_avatar.png'

  Paperclip.interpolates :imageable_type  do |attachment, _style|
      attachment.instance.imageable_type.try(:pluralize)
  end
  Paperclip.interpolates :imageable_id  do |attachment, _style|
      attachment.instance.imageable_id
  end

end
