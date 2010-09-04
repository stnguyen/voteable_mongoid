require 'post'

class Comment
  include Mongoid::Document
  include Mongoid::Voteable
  
  referenced_in :post
  
  vote_point self, :up => +1, :down => -3
  vote_point Post, :up => +2, :down => -1
end
