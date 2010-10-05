module Mongoid
  module Voteable
    extend ActiveSupport::Concern

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
      
      
      def self.vote_point(klass = self, options = nil)
        VOTE_POINT[self.name] ||= {}
        VOTE_POINT[self.name][klass.name] ||= options
      end
            

      # We usually need to show current_user his voting value on voteable object
      # voting value can be nil (not voted yet), :up or :down
      # from voting value, we can decide it should be new vote or revote with :up or :down
      # In this case, validation can be skip to maximize performance

      def self.vote(options)
        options.symbolize_keys!
        
        votee_id = options[:votee_id]
        voter_id = options[:voter_id]
        value = options[:value]
        
        votee_id = BSON::ObjectId(votee_id) if votee_id.is_a?(String)
        voter_id = BSON::ObjectId(voter_id) if voter_id.is_a?(String)

        value = value.to_sym
        value_point = VOTE_POINT[name][name]
        
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
        
        VOTE_POINT[name].each do |class_name, value_point|
          next unless association = associations[class_name.underscore]
          next unless foreign_key = options[association.options[:foreign_key].to_sym]
          foreign_key = BSON::ObjectId(foreign_key) if foreign_key.is_a?(String)

          class_name.constantize.collection.update({ :_id => foreign_key }, {
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
    end
  

    def vote(options)
      VOTE_POINT[self.class.name].each do |class_name, value_point|
        next unless association = self.class.associations[class_name.underscore]
        next unless foreign_key = association.options[:foreign_key]
        options[foreign_key] = read_attribute(foreign_key)
      end
      
      options[:votee_id] ||= _id
      options[:revote] ||= !vote_value(options[:voter_id]).nil?

      self.class.vote(options)
    end


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


    def up_votes_count
      up_voter_ids.length
    end
    

    def down_votes_count
      down_voter_ids.length
    end
    
  end
end