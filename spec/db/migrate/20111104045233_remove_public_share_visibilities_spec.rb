require 'spec_helper'
require File.join(Rails.root, "db", "migrate", "20111104045233_remove_public_share_visibilities")

describe User do
  describe '#batch_add_hidden_shareable' do
    it 'adds rows' do
      input = [{"shareable_type" => "Post", "id" => 2},
               {"shareable_type" => "Post", "id" => 4}]

      alice.should_receive(:add_hidden_shareable).with("Post", 2, {:batch => true})
      alice.should_receive(:add_hidden_shareable).with("Post", 4, {:batch => true})
      alice.batch_add_hidden_shareable(input)
    end
  end
end
