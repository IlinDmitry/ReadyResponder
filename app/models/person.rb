class Person < ActiveRecord::Base
  before_save :title_order
  
  attr_accessible :firstname, :lastname, :status, :icsid, :city, :state, :zipcode, :start_date, :title, :gender, :date_of_birth,:division1, :division2, :certs_attributes, :title_ids, :title_order
  has_many :certs, :conditions => {:status =>'Active' }
=begin
  has_many :certs do
    def active
      where{'status == "Active"' }
    end
  end
=end
  has_many :courses, :through => :certs
  has_many :skills, :through => :courses
  has_and_belongs_to_many :titles

  #accepts_nested_attributes_for :certs
  
  validates_presence_of :firstname, :lastname, :status
  validates_uniqueness_of :icsid, :allow_nil => true, :allow_blank => true   # this needs to be scoped to active members, or more sophisticated rules
  validates_length_of :state, :is =>2, :allow_nil => true, :allow_blank => true
  validates_numericality_of  :height, :weight, :allow_nil => true, :allow_blank => true
  validates_presence_of :division2, :unless => "division1.blank?"
  validates_presence_of :division1, :unless => "division2.blank?"
  
  
  scope :leave, :conditions => {:status => "Leave of Absence"}
  scope :inactive, :conditions => {:status => "Inactive"}
  scope :active, :order => 'division1, division2, title_order, start_date ASC', :conditions => {:status => "Active"}
  scope :divisionC, :order => 'title_order, start_date ASC', :conditions => {:division1 => "Command", :status => "Active"}
  scope :division1, :order => 'title_order, start_date ASC', :conditions => {:division1 => "Division 1", :status => "Active"}
  scope :division2, :order => 'title_order, start_date ASC', :conditions => {:division1 => "Division 2", :status => "Active"}
  scope :squadC, :order => 'title_order, start_date ASC', :conditions => {:division2 => "Command", :status => "Active"}
  scope :unassigned, :order => 'title_order, start_date ASC', :conditions => {:division1 => "Unassigned", :status => "Active"}
  scope :squad1, :order => 'title_order, start_date ASC', :conditions => {:division2 => "Squad 1",:status => "Active"}
  scope :squad2, :order => 'title_order, start_date ASC', :conditions => {:division2 => "Squad 2",:status => "Active"}

  TITLES = ['Director','Chief','Deputy','Captain', 'Lieutenant','Sargeant', 'Corporal', 'Senior Officer', 'Officer', 'CERT', 'Dispatcher', 'Recruit','Student Officer']
  TITLE_ORDER = {'Director' => 1, 'Chief' => 3, 'Deputy Chief' => 5,'Captain' => 7, 'Lieutenant' => 9, 'Sargeant' => 11, 'Corporal' => 13, 'Senior Officer' => 15, 'Officer' => 17, 'CERT Member' => 19, 'Dispatcher' => 19, 'Student Officer' => 21}
  
  def fullname
    (self.firstname + " " + (self.middleinitial || "") + " " + self.lastname).squeeze(" ")
  end
  
  def shortrank
    ranks = { "Chief" => "Chief", "Deputy Chief" => "Deputy", "Captain" => "Capt",
            "Lieutenant" => "Lt", "Sargeant" => "Sgt", "Corporal" => "Cpl",
            "Senior Officer" => "SrO", "Officer" => "Ofc", "Dispatcher" => "Dsp",
            "Recruit" => "Rct" }
    ranks[self.title] || ''
  end
  def title_order
    self.title_order = TITLE_ORDER[self.title] || 30
  end
  
  def name
    (self.firstname + " " + self.lastname)
  end
  
  def csz
    self.city + " " + self.state + " " + self.zipcode
  end
  
  def self.search(search)
    if search
      find :all, :conditions => ['firstname LIKE ? OR lastname LIKE ? OR city LIKE ? OR memberID like ?',
        "%#{search}%","%#{search}%","%#{search}%","%#{search}%"],
        :order => 'division1, division2,title_order, start_date ASC'
    else
      find :all, :order => 'division1, division2,title_order, start_date ASC'
    end
  end
  def age
    if self.date_of_birth.present?
      now = Date.today
      age = now.year - self.date_of_birth.year
      age -= 1 if now.yday < self.date_of_birth.yday
    end
      age
  end
  
  def skilled?(skill_name)
    skill = Skill.find_by_name(skill_name)
    if skill.blank?
      false
    else
      #self.certs.active.courses.skills.include?(skill)
      self.skills.include?(skill)
    end
  end
  
  def qualified?(title_name)
    title = Title.find_by_name(title_name)
    if title
      (title.skills - self.skills).empty?  # then true
    else
      false
    end
  end
  def service_duration
    if self.start_date.present?
      if self.end_date.present?
        self.end_date.year - self.start_date.year + ( self.start_date.yday < self.end_date.yday ? 1 : 0 )
      else
        Date.today.year - self.start_date.year + ( self.start_date.yday < Date.today.yday ? 1 : 0 )
      end
    end
  end
  
end