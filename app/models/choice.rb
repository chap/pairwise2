class Choice < ActiveRecord::Base
  include Activation
  
  belongs_to :question, :counter_cache => true
  belongs_to :item
  belongs_to :creator, :class_name => "Visitor", :foreign_key => "creator_id"
  
  validates_presence_of :creator, :on => :create, :message => "can't be blank"
  validates_presence_of :question, :on => :create, :message => "can't be blank"
  #validates_length_of :item, :maximum => 140
  
  has_many :votes
  has_many :prompts_on_the_left, :class_name => "Prompt", :foreign_key => "left_choice_id"
  has_many :prompts_on_the_right, :class_name => "Prompt", :foreign_key => "right_choice_id"
  named_scope :active, :conditions => { :active => true }
  named_scope :inactive, :conditions => { :active => false}
  
  #attr_accessor :data
  
  def question_name
    question.name
  end
  
  def item_data
    item.data
  end
  
  def lose!
    self.loss_count += 1 rescue (self.loss_count = 1)
    self.score = compute_score
    save!
  end
  
  def wins_plus_losses
    #(prompts_on_the_left.collect(&:votes_count).sum + prompts_on_the_right.collect(&:votes_count).sum)
    #Prompt.sum('votes_count', :conditions => "left_choice_id = #{id} OR right_choice_id = #{id}")
    wins + losses
  end
  
  def losses
    loss_count || 0
  end
  
  def wins
    votes_count || 0
  end
  
  after_create :generate_prompts
  def before_create
    puts "just got inside choice#before_create. is set to active? #{self.active?}"
    unless item
      @item = Item.create!(:creator => creator, :data => data)
      self.item = @item
    end
    unless self.score
      self.score = 50.0
    end
    unless self.active?
      puts "this choice was not specifically set to active, so we are now asking if we should auto-activate"
      self.active = question.should_autoactivate_ideas? ? true : false
      puts "should question autoactivate? #{question.should_autoactivate_ideas?}"
      puts "will this choice be active? #{self.active}"
    end
    return true #so active record will save
  end
  
  def compute_score
    # if wins_plus_losses == 0
    #   return 0
    # else
    #   (wins.to_f / wins_plus_losses ) * 100
    # end
    (wins.to_f+1)/(wins+1+losses+1) * 100
  end
  
  def compute_score!
    self.score = compute_score
    save!
  end

  def user_created
    self.item.creator_id != self.question.creator_id
  end

  def compute_bt_score(btprobs = nil)
      if btprobs.nil?
	      btprobs = self.question.bradley_terry_probs
      end

      p_i = btprobs[self.id]

      total = 0
      btprobs.each do |id, p_j|
	      if id == self.id
		      next
	      end

	      total += (p_i / (p_i + p_j))
      end

      total / (btprobs.size-1)

  end

  
  protected

  def generate_prompts
    previous_choices = (self.question.choices - [self])

    if previous_choices.any?
      sql = []
      previous_choices.each do |choice|
        sql << {:question_id => self.question_id, :left_choice_id => choice.id, :votes_count => 0, :right_choice_id => self.id}
        sql << {:question_id => self.question_id, :left_choice_id => self.id, :votes_count => 0, :right_choice_id => choice.id}
      end
      Prompt.create([sql])
      Question.update_counters(self.question_id, :prompts_count => 2*previous_choices.size)
    end
  end
end
