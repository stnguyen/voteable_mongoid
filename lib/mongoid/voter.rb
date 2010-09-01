module Mongoid
  module Voter
    extend ActiveSupport::Concern

    included do
    end
  
    def votees(klass)
      klass.any_of({ :up_voter_ids => _id }, { :down_voter_ids => _id })
    end
  end
end