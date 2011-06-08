class User
  include ActiveModel::Validations

  attr_accessor :website

  validates :website, :url => {:message => 'bad bad URL'}

end

