require "spec_helper"

describe Mongoid::Voter do
  before :all do
    Mongoid::database.connection.drop_database(Mongoid::database.name)

    @post1 = Post.create!
    @post2 = Post.create!

    @user1 = User.create!
    @user2 = User.create!
  end
  
  context "just created" do
    it '' do
      @user1.votees(Post).should be_empty
      @user1.voted?(@post1).should be_false
      @user1.voted?(@post2).should be_false
      
      @user2.votees(Post).should be_empty
      @user2.voted?(@post1).should be_false
      @user2.voted?(@post2).should be_false
    end
    
    it 'revote has no effect' do      
      @user2.vote(:revote => true, :votee => @post2, :value => :down)
      @post2.reload
      
      @post2.votes_count.should == 0
      @post2.votes_point.should == 0
    end
  end
  
  context 'user1 vote up post1 the first time' do
    before :all do    
      @user1.vote(:revote => '', :votee_id => @post1.id, :votee_type => 'Post', :value => :up)
      @post1.reload
    end
    
    it '' do
      @post1.votes_count.should == 1
      @post1.votes_point.should == 1

      @user1.vote_value(@post1).should == :up
      @user2.vote_value(:votee_type => 'Post', :votee_id => @post1.id).should be_nil
      
      @user1.should be_voted(@post1)
      @user2.should_not be_voted(:votee_type => 'Post', :votee_id => @post1.id)
      
      @user1.votees(Post).to_a.should == [ @post1 ]
      @user2.votees(Post).to_a.should be_empty
    end
    
    it 'user1 vote post1 has no effect' do
      @user1.vote(:votee => @post1, :value => :up)
      @post1.reload
      
      @post1.votes_count.should == 1
      @post1.votes_point.should == 1
      
      @post1.vote_value(@user1.id).should == :up
    end
  end
  
  context 'user2 vote down post1 the first time' do
    before :all do
      @user2.vote(:votee => @post1, :value => :down)
      @post1.reload
    end
    
    it '' do
      @post1.votes_count.should == 2
      @post1.votes_point.should == 0
      
      @user1.vote_value(@post1).should == :up
      @user2.vote_value(@post1).should == :down

      @user1.votees(Post).to_a.should == [ @post1 ]
      @user2.votees(Post).to_a.should == [ @post1 ]
    end
  end
  
  context 'user1 change vote on post1 from up to down' do
    before :all do
      @user1.vote(:votee => @post1, :value => :down)
      @post1.reload
    end
    
    it '' do
      @post1.votes_count.should == 2
      @post1.votes_point.should == -2

      @user1.vote_value(@post1).should == :down
      @user2.vote_value(@post1).should == :down

      @user1.votees(Post).to_a.should == [ @post1 ]
      @user2.votees(Post).to_a.should == [ @post1 ]
    end
  end
  
  context 'user1 vote down post2 the first time' do
    before :all do
      @user1.vote(:new => 'abc', :votee => @post2, :value => :down)
      @post2.reload
    end
    
    it '' do
      @post2.votes_count.should == 1
      @post2.votes_point.should == -1
      
      @user1.vote_value(@post2).should == :down
      @user2.vote_value(@post2).should be_nil

      @user1.votees(Post).to_a.should == [ @post1, @post2 ]
    end
  end
  
  context 'user1 change vote on post2 from down to up' do
    before :all do
      @user1.vote(:revote => 'abc', :votee => @post2, :value => :up)
      @post2.reload
    end
    
    it '' do
      @post2.votes_count.should == 1
      @post2.votes_point.should == 1
      
      @user1.vote_value(@post2).should == :up
      @user2.vote_value(@post2).should be_nil

      @user1.votees(Post).to_a.should == [ @post1, @post2 ]
    end
  end  
end