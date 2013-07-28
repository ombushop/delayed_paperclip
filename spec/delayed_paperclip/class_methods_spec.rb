require 'spec_helper'
require 'resque'

describe DelayedPaperclip::ClassMethods do

  before :all do
    reset_dummy(with_processed: false)
  end

  describe ".process_in_background" do

    it "is empty to start" do
      Dummy.attachment_definitions.should == { :image => {} }
    end

    it "adds basics to attachment_definitions" do
      Dummy.process_in_background(:image)
      Dummy.attachment_definitions.should == { :image => {
        :delayed => {
          :priority => 0,
          :only_process => nil,
          :url_with_processing => true,
          :processing_image_url => nil}
        }
      }
    end

    context "with processing_image_url" do
      before :each do
        Dummy.process_in_background(:image, processing_image_url: "/processing/url")
      end

      it "incorporates processing url" do
        Dummy.attachment_definitions.should == { :image => {
          :delayed => {
            :priority => 0,
            :only_process => nil,
            :url_with_processing => true,
            :processing_image_url => "/processing/url"}
          }
        }
      end
    end

    context "inherits only_process options" do
      before :each do
        reset_class("Dummy", paperclip: { only_process: [:small, :large] } )
        Dummy.process_in_background(:image)
      end

      it "incorporates processing url" do
        Dummy.attachment_definitions.should == { :image => {
          :only_process => [:small, :large],
          :delayed => {
            :priority => 0,
            :only_process => [:small, :large],
            :url_with_processing => true,
            :processing_image_url => nil }
          }
        }
      end
    end

    context "sets callback" do
      context "commit" do
        it "sets after_commit callback" do
          Dummy.expects(:after_commit).with(:enqueue_delayed_processing)
          Dummy.process_in_background(:image)
        end
      end

      context "save" do
        before :each do
          Dummy.stubs(:respond_to?).with(:after_commit).returns(false)
        end

        it "sets after_save callback" do
          Dummy.expects(:after_save).with(:enqueue_delayed_processing)
          Dummy.process_in_background(:image)
        end
      end
    end
  end

end