module Mongoid
  module Voter
    extend ActiveSupport::Concern

    # Get list of voted votees
    #
    # @param [Class] klass the votee class, e.g. `Post` or `Comment`
    # @return [Array, nil] an array of voteable objects voted by this voter
    def votees(klass)
      klass.any_of({ "voteable.up_voter_ids" => _id }, { "voteable.down_voter_ids" => _id })
    end

    # Check to see if this voter voted on the votee or not
    #
    # @param [Hash, Object] options the hash containing the votee, or the votee itself
    # @return [true, false] true if voted, false otherwise
    def voted?(options)
      unless options.is_a?(Hash)
        votee_class = options.class
        votee_id = options._id
      else
        votee = options[:votee]
        if votee
          votee_class = votee.class
          votee_id = votee._id
        else
          votee_class = options[:votee_type].classify.constantize
          votee_id = options[:votee_id]
        end
      end
      
      votees(votee_class).where(:_id => votee_id).count == 1
    end

    # Get the voted value on a votee
    #
    # @param (see #voted?)
    # @return [Symbol, nil] :up or :down or nil if not voted
    def vote_value(options)
      votee = unless options.is_a?(Hash)
        options
      else
        options[:votee] || options[:votee_type].classify.constantize.only(:up_vote_ids, :down_vote_ids).where(
          :_id => options[:votee_id]
        ).first
      end
      votee.vote_value(_id)
    end
    
    # Cancel the vote on a votee
    #
    # @param [Object] votee the votee to be unvoted
    def unvote(options)
      unless options.is_a?(Hash)
        options = { :votee => options }
      end
      options[:unvote] = true
      options[:revote] = false
      vote(options)
    end

    # Vote on a votee
    #
    # @param (see #voted?)
    # @param [:up, :down] vote_value vote up or vote down, nil to unvote
    def vote(options, value = nil)
      if options.is_a?(Hash)
        votee = options[:votee]
      else
        votee = options
        options = { :votee => votee, :value => value }
      end

      if votee
        options[:votee_id] = votee._id
        votee_class = votee.class
      else
        votee_class = options[:votee_type].classify.constantize
      end
      
      if options[:value].nil?
        options[:unvote] = true
        options[:value] = vote_value(options)
      else
        options[:revote] = options.has_key?(:revote) ? !options[:revote].blank? : voted?(options)
      end
      
      options[:voter_id] = _id

      ( votee || votee_class ).vote(options)
    end
  end
end
