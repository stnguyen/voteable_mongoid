module Mongoid
  module Votable
    extend ActiveSupport::Concern

    included do
      field :up_voter_ids, :type => Array, :default => []
      field :down_voter_ids, :type => Array, :default => []
    
      field :votes_count, :type => Integer, :default => 0
      field :votes_point, :type => Integer, :default => 0
    
      index :up_voter_ids
      index :down_voter_ids
      index :votes_count
      index :votes_point

      def self.update_vote(_id, voter_id, up)
        if up
          push_field = :up_voter_ids
          pull_field = :down_voter_ids
          point_delta = +2
        else
          push_field = :down_voter_ids
          pull_field = :up_voter_ids
          point_delta = -2
        end

        collection.update({ :_id => _id }, {
          '$pull' => { pull_field => voter_id },
          '$push' => { push_field => voter_id },
          '$inc' => {
            :votes_point => point_delta
          }
        })
      end
    

      def self.new_vote(_id, voter_id, up)
        if up
          push_field = :up_voter_ids
          point_delta = +1
        else
          push_field = :down_voter_ids
          point_delta = -1
        end

        collection.update({ :_id => _id }, {
          '$push' => { push_field => voter_id },
          '$inc' => {
            :votes_count => +1,
            :votes_point => point_delta
          }
        })
      end    
    end
  
    def vote_value(voter_id)
      return :up if up_voter_ids.include?(voter_id)
      return :down if down_voter_ids.include?(voter_id)
    end
  end
end