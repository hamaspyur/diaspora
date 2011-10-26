class DiasporaEnviroment
  attr_accessor :remote_diasporian, :remote_diasporian_encryption_key

  def remote_diasporian
    @remote_diasporian ||= lambda do
      user = Factory(:user)
      @remote_diasporian_encryption_key = user.encryption_key
      remote_diasporian ||= user.person
      user.delete
      remote_diasporian.owner_id = nil
      remote_diasporian.save
      remote_diasporian
    end.call
  end

  #note, post must be from a local user to this pod
  def xml_of_remote_diasporian_commenting_on(p)
    @xml ||= lambda do
      remote_comment = Factory(:comment, :post => p, :author => remote_diasporian)
      remote_comment.parent_author_signature = remote_comment.sign_with_key(p.author.owner.encryption_key)
      xml = remote_comment.to_diaspora_xml
      remote_comment.destroy
      xml
    end.call
  end

  def remote_user_is_connected_to(user)
    user.share_with(remote_diasporian, user.aspects.where(:name => 'generic'))
  end

  def remote_user_private_salmon_xml(activity_xml, receiving_person)
    Salmon::EncryptedSlap.create_by_user_and_activity(remote_diasporian_user_stub, activity_xml).xml_for(receiving_person)
  end

  def xml_of_remote_diasporian_commenting_on_local_users_post(user, p)
    xml = xml_of_remote_diasporian_commenting_on(p)
    remote_user_private_salmon_xml(xml, user.person)
  end

  private

  def remote_diasporian_user_stub
    Struct.new("FakeUser", :person, :encryption_key)
    Struct::FakeUser.new(remote_diasporian, @remote_diasporian_encryption_key)
  end
end
