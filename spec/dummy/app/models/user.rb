#require 'devise/async'
class User < AbstractAdapter
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable, :lockable

  scope :active,   -> { where(:locked_at => nil) }
  scope :inactive, -> { where('locked_at is not null') }

  has_many :user_locations, dependent: :destroy

  has_many :user_project_jobs, dependent: :destroy, inverse_of: :user
  has_many :jobs,     through: :user_project_jobs, inverse_of: :users
  has_many :projects, through: :user_project_jobs, inverse_of: :users
  accepts_nested_attributes_for :user_project_jobs

  before_validation :set_default_password_from_project, on: :create

  has_many :team_users
  has_many :teams, through: :team_users

  has_one :avatar, class_name: 'Image', as: :imageable
  accepts_nested_attributes_for :avatar, allow_destroy: true


  has_many :own_chats, foreign_key: :creator_id, class_name: 'Chat'
  has_many :chat_users
  has_many :chats, through: :chat_users
  has_many :chat_message_users
  has_many :messages, ->{ where('chat_messages.created_at >= chat_users.created_at and (chat_users.departed_at IS NULL OR chat_messages.created_at <= chat_users.departed_at)') }, through: :chats 
  include User::Chatter

  has_many :roles, dependent: :destroy, inverse_of: :user
  accepts_nested_attributes_for :roles, allow_destroy: true
  has_many :admin_companies, through: :roles, source: :ownable, source_type: Company
  has_many :admin_projects,  through: :roles, source: :ownable, source_type: Project

  def all_admin_projects # aggregate companies' projects with project admin roles
    (admin_companies.map(&:projects)+admin_projects).flatten
  end

  def superuser?
    superuser
  end

  def admin?(record)
    superuser? || roles.detect{|r| r.ownable == record }.present?
  end

  def company_admin? # an admin of any company
    superuser? || roles.detect{|r| r.ownable_type == 'Company' }.present?
  end

  def project_admin? # an admin of any project
    superuser? || company_admin? || roles.detect{|r| r.ownable_type == 'Project' }.present?
  end


  def set_default_password_from_project
    self.password = user_project_jobs.first.try(:project).try(:default_password) if password.blank?
  end

  def name
    [first_name,last_name].delete_if(&:blank?).join(' ')
  end

  def avatar_url(size='medium')
    avatar.try(:file).try(:url,size)
  end

  def self.grape_param_types
    { "skip_confirmation_email" => Virtus::Attribute::Boolean }
  end

  def skip_confirmation_email=(s)
    return unless s.to_s == "true"
    # skip_confirmation! does not work with update_attributes, a work-around:
    self.update_column(:email, email) && self.reload if self.valid? && self.id
    # devise: confirm the user without requiring a confirmation email
    self.skip_confirmation!
  end

end
