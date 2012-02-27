#takes anything that can be handled by Diaspora::Parser, so basically
# anything ROXMLified

require File.join(Rails.root, 'lib/diaspora/parser')

class Diaspora::Federated::Parser
  attr_accessor :xml, :sender, :object

  def initialize(xml, sender)
    self.xml = xml
    self.sender = sender
  end

  def parse!
    #we might need a begin rescue here
    self.object = Diaspora::Parser.from_xml(xml)

    #crazy munging side effects  :(
    assign_sender_handle_if_request!
    update_actor_to_reflect_object_author!

    self.object
  end

  private

  def assign_sender_handle_if_request!
    #special casey  
    if object.is_a?(Request)
      object.sender_handle = sender.diaspora_handle
    end
  end

  def update_actor_to_reflect_object_author!
    if actor = Webfinger.new(object.diaspora_handle).fetch 
      object.author = actor if object.respond_to? :author=
      object.person = actor if object.respond_to? :person=
    end
  end
end
