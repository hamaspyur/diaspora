class Diaspora::Federated::Validator::Private
  include ActiveModel::Validations

  attr_accessor :salmon, :user, :sender, :object

  validate :relayable_object_has_parent
  validate :contact_required
  validate :xml_author_matchs_a_known_party
  validate :model_is_valid?

  def initialize(salmon, user, sender)
    self.salmon = salmon
    self.user = user
    self.sender = sender
  end

  def process!
    return nil unless valid_signature_on_envelope? #parsing can be $$$ so do it first

    #may need to handle case where parse returns nil
    if self.valid?
      object 
    else
      raise self.errors.inspect
      FEDERATION_LOGGER.info("Failed Private Receive: #{self.errors.inspect}")
      nil
    end
  end

  def object
    @object ||= Diaspora::Federated::Parser.new(salmon.parsed_data, sender).parse!
  end

  private

  #weird
  def valid_signature_on_envelope?
    unless sender.present? && self.salmon.verified_for_key?(sender.public_key)
      raise "oh no"
      errors.add :salmon, "sender failed key check"
    end
  end

  #if the current receiveing user is the owner of the parent post, you know about the commenter, so proceeded
  #if you dont own the post, assume the xml_author is the author of the parent post, as that is the person who
  #is going to be sending you the comment
  def known_party
    if object.respond_to?(:relayable?)
      #if A and B are friends, and A sends B a comment from C, we delegate the validation to the owner of the post being commented on
      user.owns?(object.parent) ? object.diaspora_handle : object.parent.author.diaspora_handle
    else
      object.diaspora_handle
    end
  end

  #validations

  def relayable_object_has_parent
    if object.respond_to?(:relayable?) && object.parent.nil?

      raise "relayable"
      errors.add :base, "Relayable Object has no known parent."
    end
  end

  def contact_required
    unless object.is_a?(Request) || user.contact_for(sender).present?
      raise "contact"
      errors.add :base, "Contact Required to receive object."
    end
  end

  def xml_author_matchs_a_known_party
    unless object.author.diaspora_handle == known_party
      raise "xml"
      errors.add :base, "XML author does not match a known party."
    end
  end

  def model_is_valid?
    unless object.valid?
      errors.add :base, "Invalid Object: #{object.errors.inspect}"
    end
  end
end