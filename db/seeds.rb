u = User.create!(:email => 'pairwisetest@dkapadia.com',
                 :password => 'wheatthins', 
                 :password_confirmation => 'wheatthins')
u.email_confirmed = true
u.save!