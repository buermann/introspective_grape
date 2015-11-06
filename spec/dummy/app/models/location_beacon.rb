class LocationBeacon < AbstractAdapter
  belongs_to :location
  has_many :gps, through: :location
  belongs_to :company

  # B9407F30-F5F8-466E-AFF9-25556B57FE6D
  validates_format_of :uuid, with: /[0-9a-fA-F]{32}/ # 32 digit hexadecimal UUID
  validates_format_of :mac_address, with: /[0-9a-fA-F]{12}/ # 16 digit hexadecimal bluetooth MAC address

  before_validation :massage_ids
  def massage_ids
    self.uuid        = (uuid||'').gsub(/[^0-9a-fA-F]+/,'').upcase
    self.mac_address = (mac_address||'').gsub(/[^0-9a-fA-F]+/,'').upcase
  end

end
