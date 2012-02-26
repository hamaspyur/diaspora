#   Copyright (c) 2010-2011, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.
require File.join(Rails.root, 'lib/webfinger')
require File.join(Rails.root, 'lib/diaspora/federated/parser')
require File.join(Rails.root, 'lib/diaspora/federated/validator/private')

class Postzord::Receiver::Private < Postzord::Receiver

  def initialize(user, opts={})
    @user = user
    @salmon_xml = opts[:salmon_xml]
    @sender = opts[:person] || Webfinger.new(self.salmon.author_id).fetch
    @actor = @sender
    @object = opts[:object]
  end
  
  #called from xml provided by the outside world
  def receive!
    validator = Diaspora::Federated::Validator::Private.new(self.salmon, @user, @sender)
    if @object = validator.process! 
      receive_object
    else
      FEDERATION_LOGGER.info("event=receive status=abort recipient=#{@user.diaspora_handle} sender=#{@salmon.author_id} reason='not_verified for key'")
    end
  end  

  #called from local code paths only, so we dont need to do all the validation checks
  def parse_and_receive(xml)
    @object = Diaspora::Federated::Parser.new(xml, @sender).parse!
    receive_object
  end

  protected

  # @return [Object]
  def receive_object
    obj = @object.receive(@user, @object.author)
    puts obj.inspect
    Notification.notify(@user, obj, @author) if obj.respond_to?(:notification_type)
    FEDERATION_LOGGER.info("user:#{@user.id} successfully received private post from person#{@sender.guid} #{@object.inspect}")
    obj
  end

  def salmon
    @salmon ||= Salmon::EncryptedSlap.from_xml(@salmon_xml, @user)
  end
end