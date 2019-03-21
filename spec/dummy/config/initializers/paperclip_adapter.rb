module Paperclip
  class HashUploadedFileAdapter < AbstractAdapter
    def initialize(target, args)
      @tempfile, @content_type, @size = target['tempfile'], target['type'], target['tempfile'].size
      @original_filename = target['filename']
    end

  end
end

#Paperclip.io_adapters.register Paperclip::HashUploadedFileAdapter do |target|
#  target.kind_of? Hash
#end
