class AssignmentSubmission < ActiveRecord::Base
  attr_accessible :assignment_id, :comment, :feedback, :group_id, :attachment, :link, :submittable_id, :submittable_type
  
  include Canable::Ables  
  
  
  #has_attached_file :attachment
  
  belongs_to :submittable, :polymorphic => :true
  belongs_to :assignment
  has_one :grade
  
  validates_presence_of :assignment_id, :submittable_id, :submittable_type
  
  scope :been_graded, where(:grade != nil)
  
  def updatable_by?(user)
    creator == user
  end
  
  def destroyable_by?(user)
    updatable_by?(user)
  end
  
end
