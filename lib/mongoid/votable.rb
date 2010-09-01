module Mongoid
  module Votable
    extend ActiveSupport::Concern

    included do
      field :up_voter_ids, :type => Array, :default => []
      field :down_voter_ids, :type => Array, :default => []
    
      field :votes_count, :type => Integer, :default => 0
      field :votes_point, :type => Integer, :default => 0
    
      index :votes_count
      index :votes_point

      def self.update_vote(options)
        votee_id = options[:votee_id]
        voter_id = options[:voter_id]
        value = options[:value]
        
        votee_id = BSON::ObjectID(votee_id) if votee_id.is_a?(String)
        voter_id = BSON::ObjectID(voter_id) if voter_id.is_a?(String)
        
        if value == :up
          push_field = :up_voter_ids
          pull_field = :down_voter_ids
          point_delta = +2
        else
          push_field = :down_voter_ids
          pull_field = :up_voter_ids
          point_delta = -2
        end

        collection.update({ :_id => votee_id }, {
          '$pull' => { pull_field => voter_id },
          '$push' => { push_field => voter_id },
          '$inc' => {
            :votes_point => point_delta
          }
        })
      end
    

      def self.new_vote(options)
        votee_id = options[:votee_id]
        voter_id = options[:voter_id]
        value = options[:value]      
        
        votee_id = BSON::ObjectID(votee_id) if votee_id.is_a?(String)
        voter_id = BSON::ObjectID(voter_id) if voter_id.is_a?(String)
        
        if value == :up
          push_field = :up_voter_ids
          point_delta = +1
        else
          push_field = :down_voter_ids
          point_delta = -1
        end

        collection.update({ :_id => votee_id }, {
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