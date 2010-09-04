module Mongoid
  module Voter
    extend ActiveSupport::Concern


    def votees(klass)
      klass.any_of({ :up_voter_ids => _id }, { :down_voter_ids => _id })
    end


    def voted?(options)
      unless options.is_a?(Hash)
        votee_class = options.class
        votee_id = options._id
      else
        votee = options[:votee]
        if votee
          votee_class = votee.class
          votee_id = votee.id
        else
          votee_class = options[:votee_type].classify.constantize
          votee_id = options[:votee_id]
        end
      end
      
      votees(votee_class).where(:_id => votee_id).count == 1
    end


    def vote_value(options)
      votee = unless options.is_a?(Hash)
        options
      else
        options[:votee_type].classify.constantize.only(:up_vote_ids, :down_vote_ids).where(
          :_id => options[:votee_id]
        ).first
      end
      votee.vote_value(_id)
    end
    
  
    def vote(options, vote_value = nil)
      options.symbolize_keys!

      if options.is_a?(Hash) 
        votee = options[:votee]
      else
        votee = options
        options = { :votee => votee, :value => vote_value }
      end

      if votee
        options[:votee_id] = votee.id
        votee_class = votee.class
      else
        votee_class = options[:votee_type].classify.constantize
      end
      
      options[:revote] = if options.has_key?(:revote)
        !options[:revote].blank?
      else
        options.has_key?(:new) ? options[:new].blank? : voted?(options)
      end
      
      options[:voter_id] = _id

      ( votee || votee_class ).vote(options)
    end
  end
end