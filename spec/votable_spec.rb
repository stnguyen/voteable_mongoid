require "spec_helper"

describe Mongoid::Votable do
  before :all do
    User.delete_all
    Post.delete_all
    
    @post1 = Post.create!
    @post2 = Post.create!

    @user1 = User.create!
    @user2 = User.create!
  end
  
  context "just created" do
    it 'votable votes_count, votes_point should be zero' do
      @post1.votes_count.should == 0
      @post1.votes_point.should == 0

      @post2.votes_count.should == 0
      @post2.votes_point.should == 0
    end
    
    it 'votable up_voter_ids, down_voter_ids should be empty' do
      @post1.up_voter_ids.should be_empty
      @post1.down_voter_ids.should be_empty

      @post2.up_voter_ids.should be_empty
      @post2.down_voter_ids.should be_empty
    end
    
    it 'voter votees should be empty' do
      @user1.votees(Post).should be_empty
      @user2.votees(Post).should be_empty
    end
  end
  
  context 'user1 vote up post1 the first time' do
    before :all do    
      Post.new_vote(@post1.id, @user1.id, true)
      @post1.reload
    end
    
    it '' do
      @post1.votes_count.should == 1
      @post1.votes_point.should == 1

      @user1.votees(Post).should == [ @post1 ]
      @user2.votees(Post).should be_empty
    end
  end
  
  context 'user2 vote down post1 the first time' do
    before :all do
      Post.new_vote(@post1.id, @user2.id, false)
      @post1.reload
    end
    
    it '' do
      @post1.votes_count.should == 2
      @post1.votes_point.should == 0
      
      @user1.votees(Post).should == [ @post1 ]
      @user2.votees(Post).should == [ @post1 ]
    end
  end
  
  context 'user1 change vote on post1 from up to down' do
    before :all do
      Post.update_vote(@post1.id, @user1.id, false)
      @post1.reload
    end
    
    it '' do
      @post1.votes_count.should == 2
      @post1.votes_point.should == -2

      @user1.votees(Post).should == [ @post1 ]
      @user2.votees(Post).should == [ @post1 ]
    end
  end
  
  context 'user1 vote down post2 the first time' do
    before :all do
      Post.new_vote(@post2.id, @user1.id, false)
      @post2.reload
    end
    
    it '' do
      @post2.votes_count.should == 1
      @post2.votes_point.should == -1
      
      @user1.votees(Post).should == [ @post1, @post2 ]
    end
  end
  
  context 'user1 change vote on post2 from down to up' do
    before :all do
      Post.update_vote(@post2.id, @user1.id, true)
      @post2.reload
    end
    
    it '' do
      @post2.votes_count.should == 1
      @post2.votes_point.should == 1
      
      @user1.votees(Post).should == [ @post1, @post2 ]
    end
  end
end