#   Copyright (c) 2010-2011, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.
require File.join(Rails.root, 'lib/webfinger')
require File.join(Rails.root, 'lib/diaspora/federated/parser')
require File.join(Rails.root, 'lib/diaspora/federated/validator/private')



#there are three phases of this object
# 1. accept xml
# 2.validate and emit the object
# 3. recieve the object by the user
# 4. post recieve callbacks
# 
class Postzord::Receiver::Private < Postzord::Receiver
  attr_accessor :object, :user, :sender, :salmon, :salmon_xml
  def initialize(user, opts={})
    self.user = user
    self.salmon_xml = opts[:salmon_xml]
    self.sender = opts[:person] || Webfinger.new(self.salmon.author_id).fetch
    @actor = @sender
    self.object = opts[:object]
  end


  #called from xml provided by the outside world
  def receive!
    validator = Diaspora::Federated::Validator::Private.new(self.salmon, @user, @sender)
    if self.object = validator.process!
      refreshed_object = accept_object_for_user #this SHOULD emit an instance of the object if it already exists
      post_receive_hooks(refreshed_object)
    else
      puts validator.errors.inspect
      FEDERATION_LOGGER.info("failed to receive object: #{validator.errors.inspect}")
      false
    end
  end

  #called from local code paths only, so we dont need to do all the validation checks
  def parse_and_receive(xml)
    self.object = create_object_from_local(xml)
    obj = accept_object_for_user
    # post_receive_hooks(obj)
  end

  # @return [Object]
  def accept_object_for_user
    begin
    obj = object.receive(@user, object.author)
    rescue Exception => e
      puts @object.inspect
      raise e
    end
    FEDERATION_LOGGER.info("user:#{@user.id} successfully received private post from person#{@sender.guid} #{@object.inspect}")
    obj
  end

  def post_receive_hooks(obj)
    notify_receiver(obj)
  end

  protected

  def create_object_from_local(xml)
     Diaspora::Federated::Parser.new(xml, @sender).parse!
  end

  def salmon
    @salmon ||= Salmon::EncryptedSlap.from_xml(@salmon_xml, @user)
  end

  def notify_receiver(obj)
    if obj.respond_to?(:notification_type)
      Notification.notify(@user, obj, @object.author) 
    else
      FEDERATION_LOGGER.info("WARNING: object #{obj.inspect}: did not respond_t0 notification_type")
    end
  end
end