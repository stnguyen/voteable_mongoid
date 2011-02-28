module Mongoid
  module Voteable
    extend ActiveSupport::Concern

    # How many points should be assigned for each up or down vote.
    # This array should be manipulated using Voteable.vote_point method
    VOTE_POINT = {}

    included do
      field :up_voter_ids, :type => Array, :default => []
      field :down_voter_ids, :type => Array, :default => []
    
      field :votes_count, :type => Integer, :default => 0
      field :votes_point, :type => Integer, :default => 0

    
      index :votes_count
      index :votes_point
      
      scope :most_voted, order_by(:votes_count.desc)
      scope :best_voted, order_by(:votes_point.desc)
      
      # Set vote point for each up (down) vote on an object of this class
      def self.vote_point(klass = self, options = nil)
        VOTE_POINT[self.name] ||= {}
        VOTE_POINT[self.name][klass.name] ||= options
      end          

      # We usually need to show current_user his voting value on voteable object
      # voting value can be nil (not voted yet), :up or :down
      # from voting value, we can decide it should be new vote or revote with :up or :down
      # In this case, validation can be skip to maximize performance

      # Make a vote on an object of this class
      #
      # @param [Hash] options a hash containings:
      #   - :votee_id: the votee document id
      #   - :voter_id: the voter document id
      #   - :value: :up or :down
      #   - :revote: change from vote up to vote down
      def self.vote(options)
        options.symbolize_keys!
        
        votee_id = options[:votee_id]
        voter_id = options[:voter_id]
        value = options[:value]
        
        votee_id = BSON::ObjectId(votee_id) if votee_id.is_a?(String)
        voter_id = BSON::ObjectId(voter_id) if voter_id.is_a?(String)

        value = value.to_sym
        value_point = VOTE_POINT[self.name][self.name]
        
        if options[:revote]
          if value == :up
            push_field = :up_voter_ids
            pull_field = :down_voter_ids
            point_delta = value_point[:up] - value_point[:down]
          else
            push_field = :down_voter_ids
            pull_field = :up_voter_ids
            point_delta = -value_point[:up] + value_point[:down]
          end
          
          collection.update({ 
            :_id => votee_id,
            push_field => { '$ne' => voter_id },
            pull_field => voter_id
          }, {
            '$pull' => { pull_field => voter_id },
            '$push' => { push_field => voter_id },
            '$inc' => {
              :votes_point => point_delta
            }
          })

        else # new vote
          if value.to_sym == :up
            push_field = :up_voter_ids
          else
            push_field = :down_voter_ids
          end

          collection.update({ 
            :_id => votee_id,
            :up_voter_ids => { '$ne' => voter_id },
            :down_voter_ids => { '$ne' => voter_id },
          }, {
            '$push' => { push_field => voter_id },
            '$inc' => {
              :votes_count => +1,
              :votes_point => value_point[value]
            }
          })
        end
        
        VOTE_POINT[self.name].each do |class_name, value_point|
          next unless relation_metadata = relations[class_name.underscore]
          next unless foreign_key_value = options[relation_metadata.foreign_key.to_sym]
          foreign_key_value = BSON::ObjectId(foreign_key_value) if foreign_key_value.is_a?(String)
          
          class_name.constantize.collection.update({ :_id => foreign_key_value }, {
            '$inc' => options[:revote] ? {
              :votes_point => ( value == :up ? 
                 value_point[:up] - value_point[:down] : 
                -value_point[:up] + value_point[:down] )
            } : {
              :votes_count => value_point[:not_increase_votes_count] ? 0 : 1,
              :votes_point => value_point[value]
            }
          })
        end
      end

      # Cancel a vote on an object of this class
      #
      # @param [Hash] options a hash containings:
      #   - :votee_id: the votee document id
      #   - :voter_id: the voter document id
      #   - :value: voted :up or :down
      def self.unvote(options)
        options.symbolize_keys!
                
        voter_id = options[:voter_id]
        voter_id = BSON::ObjectId(voter_id) if voter_id.is_a?(String)
        votee_id = options[:votee_id]
        votee_id = BSON::ObjectId(votee_id) if votee_id.is_a?(String)
        value = options[:value].to_sym
        return unless value  # not voted yet!
        
        value_point = VOTE_POINT[self.name][self.name]
        
        pull_field = if value == :up
            :up_voter_ids
        else
            :down_voter_ids
        end
        
        collection.update({ 
          :_id => votee_id,
        }, {
          '$pull' => { pull_field => voter_id },
          '$inc' => {
            :votes_count => -1,
            :votes_point => -value_point[value]
          }
        })
        
        VOTE_POINT[self.name].each do |class_name, value_point|
          next unless relation_metadata = relations[class_name.underscore]
          next unless foreign_key_value = options[relation_metadata.foreign_key.to_sym]
          foreign_key_value = BSON::ObjectId(foreign_key_value) if foreign_key_value.is_a?(String)
          
          class_name.constantize.collection.update({ :_id => foreign_key_value }, {
            '$inc' => {
              :votes_count => value_point[:not_increase_votes_count] ? 0 : -1,
              :votes_point => -value_point[value]
            }
          })
        end
      end
    end
  
    # Make a vote on this votee
    #
    # @param [Hash] options a hash containings:
    #   - :voter_id: the voter document id
    #   - :value: vote :up or vote :down
    def vote(options)
      VOTE_POINT[self.class.name].each do |class_name, value_point|
        next unless relation_metadata = relations[class_name.underscore]
        next unless foreign_key = relation_metadata.foreign_key
        options[foreign_key.to_sym] = read_attribute(foreign_key)
      end
      
      options[:votee_id] ||= _id
      options[:revote] ||= !vote_value(options[:voter_id]).nil?

      self.class.vote(options)
    end

    # Cancel a vote on this votee
    #
    # @param [Hash] options a hash containings:
    #   - :voter_id: the voter document id
    def unvote(options)
      VOTE_POINT[self.class.name].each do |class_name, value_point|
        next unless relation_metadata = relations[class_name.underscore]
        next unless foreign_key = relation_metadata.foreign_key
        options[foreign_key.to_sym] = read_attribute(foreign_key)
      end
      
      options[:votee_id] ||= _id
      options[:value] = vote_value(options[:voter_id])
      self.class.unvote(options)
    end

    # Get a voted value on this votee
    #
    # @param [String, BSON::ObjectId] x the id of the voter who made the vote
    def vote_value(x)
      voter_id = case x
      when String
        BSON::ObjectId(x)
      when BSON::ObjectId
        x
      else
        x.id
      end

      return :up if up_voter_ids.try(:include?, voter_id)
      return :down if down_voter_ids.try(:include?, voter_id)
    end

    # Get the number of up votes
    def up_votes_count
      up_voter_ids.length
    end
    
    # Get the number of down votes
    def down_votes_count
      down_voter_ids.length
    end
  end
end
