class Course < ActiveRecord::Base
  has_paper_trail
  include Loggable

  attr_accessible :category, :comments, :description, :duration, :status, :term, :name, :skill_ids
  has_many :certs
  has_many :people, :through => :certs
  has_many :events, :through => :certs
  has_and_belongs_to_many :skills

  CATEGORY_CHOICES = ['General', 'Police', 'Admin', 'CERT', 'SAR']

  validates_presence_of :name, :status
  scope :active, -> { where( status: "Active" ) }
end
