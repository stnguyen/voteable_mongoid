require "spec_helper"

describe Mongoid::Voteable do
  before :all do
    Mongoid::database.connection.drop_database(Mongoid::database.name)

    @post1 = Post.create!
    @post2 = Post.create!
    
    @comment = @post2.comments.create!

    @user1 = User.create!
    @user2 = User.create!
  end
  
  context "just created" do
    it 'voteable votes_count, votes_point should be zero' do
      @post1.votes_count.should == 0
      @post1.votes_point.should == 0

      @post2.votes_count.should == 0
      @post2.votes_point.should == 0
    end
    
    it 'voteable up_voter_ids, down_voter_ids should be empty' do
      @post1.up_voter_ids.should be_empty
      @post1.down_voter_ids.should be_empty

      @post2.up_voter_ids.should be_empty
      @post2.down_voter_ids.should be_empty
    end
    
    it 'voter votees should be empty' do
      @user1.votees(Post).should be_empty
      @user2.votees(Post).should be_empty
    end
    
    it 'revote has no effect' do
      Post.vote(:revote => true, :votee_id => @post1.id, :voter_id => @user1.id, :value => 'up')
      @post1.reload

      @post1.votes_count.should == 0
      @post1.votes_point.should == 0
      
      Post.vote(:revote => true, :votee_id => @post2.id, :voter_id => @user2.id, :value => :down)
      @post2.reload
      
      @post2.votes_count.should == 0
      @post2.votes_point.should == 0
    end
  end
  
  context 'user1 vote up post1 the first time' do
    before :all do    
      Post.vote(:votee_id => @post1.id, :voter_id => @user1.id, :value => :up)
      @post1.reload
    end
    
    it '' do
      @post1.votes_count.should == 1
      @post1.votes_point.should == 1

      @post1.vote_value(@user1).should == :up
      @post1.vote_value(@user2.id).should be_nil

      @user1.votees(Post).to_a.should == [ @post1 ]
      @user2.votees(Post).to_a.should be_empty
    end
    
    it 'user1 vote post1 has no effect' do
      Post.vote(:revote => false, :votee_id => @post1.id, :voter_id => @user1.id, :value => :up)
      @post1.reload
      
      @post1.votes_count.should == 1
      @post1.votes_point.should == 1
      
      @post1.vote_value(@user1.id).should == :up
    end
  end
  
  context 'user2 vote down post1 the first time' do
    before :all do
      Post.vote(:votee_id => @post1.id, :voter_id => @user2.id, :value => :down)
      @post1.reload
    end
    
    it '' do
      @post1.votes_count.should == 2
      @post1.votes_point.should == 0
      
      @post1.vote_value(@user1.id).should == :up
      @post1.vote_value(@user2.id).should == :down

      @user1.votees(Post).to_a.should == [ @post1 ]
      @user2.votees(Post).to_a.should == [ @post1 ]
    end
  end
  
  context 'user1 change vote on post1 from up to down' do
    before :all do
      Post.vote(:revote => true, :votee_id => @post1.id, :voter_id => @user1.id, :value => :down)
      @post1.reload
    end
    
    it '' do
      @post1.votes_count.should == 2
      @post1.votes_point.should == -2

      @post1.vote_value(@user1.id).should == :down
      @post1.vote_value(@user2.id).should == :down

      @user1.votees(Post).to_a.should == [ @post1 ]
      @user2.votees(Post).to_a.should == [ @post1 ]
    end
  end
  
  context 'user1 vote down post2 the first time' do
    before :all do
      Post.vote(:votee_id => @post2.id, :voter_id => @user1.id, :value => :down)
      @post2.reload
    end
    
    it '' do
      @post2.votes_count.should == 1
      @post2.votes_point.should == -1
      
      @post2.vote_value(@user1.id).should == :down
      @post2.vote_value(@user2.id).should be_nil

      @user1.votees(Post).to_a.should == [ @post1, @post2 ]
    end
  end
  
  context 'user1 change vote on post2 from down to up' do
    before :all do
      Post.vote(:revote => true, :votee_id => @post2.id.to_s, :voter_id => @user1.id.to_s, :value => :up)
      @post2.reload
    end
    
    it '' do
      @post2.votes_count.should == 1
      @post2.votes_point.should == 1
      
      @post2.vote_value(@user1.id).should == :up
      @post2.vote_value(@user2.id).should be_nil

      @user1.votees(Post).to_a.should == [ @post1, @post2 ]
    end
  end
  

  context 'user1 vote up post2 comment the first time' do
    before :all do
      @comment.vote(:voter_id => @user1.id, :value => :up)
      @comment.reload
      @post2.reload
    end
    
    it '' do
      @post2.votes_count.should == 2
      @post2.votes_point.should == 3
      
      @comment.votes_count.should == 1
      @comment.votes_point.should == 1
    end
  end
  
  
  context 'user1 revote post2 comment from up to down' do
    before :all do
      @user1.vote(:votee => @comment, :value => :down)
      @comment.reload
      @post2.reload
    end
    
    it '' do
      @post2.votes_count.should == 2
      @post2.votes_point.should == 0
      
      @comment.votes_count.should == 1
      @comment.votes_point.should == -3
    end
    
    it 'revote with wrong value has no effect' do
      @user1.vote(:votee => @comment, :value => :down)
      
      @post2.votes_count.should == 2
      @post2.votes_point.should == 0
      
      @comment.votes_count.should == 1
      @comment.votes_point.should == -3
    end
  end
  
  context "user1 unvote on post1" do
    before(:all) do
      @post1.vote(:voter_id => @user1.id, :votee_id => @post1.id, :unvote => true)
      @post1.reload
    end
    
    it "" do
      @post1.votes_count.should == 1
      @post1.votes_point.should == -1
      
      @post1.vote_value(@user1.id).should be_nil
      @post1.vote_value(@user2.id).should == :down
      
      @user1.votees(Post).to_a.should_not include(@post1)
    end
  end
  
  context "@post1 has 1 vote and -1 point, @post2 has 2 votes and 0 point" do
    it "" do
      Post.most_voted.first.should == @post2
      Post.best_voted.first.should == @post2
    end
  end
  
  context "user1 unvote on comment" do
    before(:all) do
      @user1.unvote(@comment)
      @comment.reload
      @post2.reload
    end
    
    it "" do
      @post2.votes_count.should == 1
      @post2.votes_point.should == 1
      
      @comment.votes_count.should == 0
      @comment.votes_point.should == 0
    end
  end
end