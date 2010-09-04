class Post
  include Mongoid::Document
  include Mongoid::Voteable

  vote_point self, :up => +1, :down => -1
  
  references_many :comments  
end
