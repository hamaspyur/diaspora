#   Copyright (c) 2010-2011, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

require 'spec_helper'

describe DiasporaEnviroment do
  before do
    @env = DiasporaEnviroment.new
  end

  describe '#remote_diasporian' do
    it 'returns a remote diasporian' do
      @env.remote_diasporian.should be_remote
    end

    it 'sets @remote_diasporian_encryption_key as a side effect' do
      @env.remote_diasporian
      @env.remote_diasporian_encryption_key.should_not be_nil
    end
  end

  describe 'xml_of_remote_diasporian_commenting_on' do
    it 'works' do
      p = Factory(:status_message, :author => alice.person)
      @env.xml_of_remote_diasporian_commenting_on(p).should_not be_nil
    end
  end

  describe 'remote_user_private_salmon_xml' do
    it 'works when you pass in valid payload xml and the person who it is to be encrypted for' do
      xml = @env.xml_of_remote_diasporian_commenting_on(Factory(:status_message, :author => alice.person))
      xml = @env.remote_user_private_salmon_xml(xml, alice.person)
    end
  end
end
