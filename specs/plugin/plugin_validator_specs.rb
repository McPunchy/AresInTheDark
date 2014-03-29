$:.unshift File.join(File.dirname(__FILE__), *%w[.. lib])

require "aresmush"

module AresMUSH

  describe Plugin do
    include MockClient
    
    before do
      SpecHelpers.stub_translate_for_testing 
    end
    
    describe :validate_check_for_login do
      before do
        @client = double
        @cmd = double
        class PluginValidateLoginTest
          include Plugin
          must_be_logged_in        
        end
        @plugin = PluginValidateLoginTest.new 
        @plugin.client = @client
        @plugin.cmd = @cmd
      end
    
      after do
        AresMUSH.send(:remove_const, :PluginValidateLoginTest)
      end
      
      it "should reject command if not logged in" do
        @client.should_receive(:logged_in?) { false }
        @plugin.validate_check_for_login.should eq 'dispatcher.must_be_logged_in'
      end
      
      it "should accept command if logged in" do
        @client.should_receive(:logged_in?) { true }
        @plugin.validate_check_for_login.should eq nil
      end
    end
    
    describe :validate_no_args do
      before do
        @client = double
        @cmd = double
        class PluginValidateRootOnlyTest
          include Plugin
          no_args
        end
        @plugin = PluginValidateRootOnlyTest.new 
        @plugin.client = @client
        @plugin.cmd = @cmd
      end
    
      after do
        AresMUSH.send(:remove_const, :PluginValidateRootOnlyTest)
      end

      it "should reject command if there are arguments" do
        @cmd.stub(:switch) { nil }
        @cmd.stub(:args) { "foo" }
        @plugin.validate_no_args.should eq "dispatcher.cmd_no_switches_or_args"
      end
      
      it "should accept command if there are no arguments" do
        @cmd.stub(:args) { nil }
        @cmd.stub(:switch) { nil }
        @plugin.validate_no_args.should eq nil
      end
      
      it "should accept command with a switch and no arguments" do
        @cmd.stub(:args) { nil }
        @cmd.stub(:switch) { nil }
        @plugin.validate_no_args.should eq nil
      end
    end    
      
    describe :validate_no_switches do
      before do
        @client = double
        @cmd = double
        class PluginValidateNoSwitchTest
          include Plugin
          no_switches
        end
        @plugin = PluginValidateNoSwitchTest.new 
        @plugin.client = @client
        @plugin.cmd = @cmd
      end
    
      after do
        AresMUSH.send(:remove_const, :PluginValidateNoSwitchTest)
      end
      
      it "should reject command if there is a switch" do
        @cmd.stub(:switch) { "foo" }
        @plugin.validate_no_switches.should eq "dispatcher.cmd_no_switches"
      end
      
      it "should allow command if there is no switch" do
        @cmd.stub(:switch) { nil }
        @plugin.validate_no_switches.should eq nil
      end
    end      
    
    describe :validate_argument_present do
      before do
        @client = double
        @cmd = double
        class PluginValidateArgumentPresentTest
          include Plugin
          attr_accessor :foo
          argument_must_be_present "foo", "test"
        end
        @plugin = PluginValidateArgumentPresentTest.new 
        @plugin.client = @client
        @plugin.cmd = @cmd
        AresMUSH::Locale.stub(:translate).with("dispatcher.invalid_syntax", { :command => "test" }) { "invalid syntax" }        
      end
    
      after do
        AresMUSH.send(:remove_const, :PluginValidateArgumentPresentTest)
      end
      
      it "should reject command if the required argument is nil" do
        @plugin.stub(:foo) { nil }
        @plugin.validate_foo_argument_present.should eq "invalid syntax"
      end
      
      it "should reject command if the required argument is blank" do
        @plugin.stub(:foo) { "   " }
        @plugin.validate_foo_argument_present.should eq "invalid syntax"
      end
      
      it "should allow command if the argument is present" do
        @plugin.stub(:foo) { "valid" }
        @plugin.validate_foo_argument_present.should eq nil
      end
    end   
    
    describe :validate_has_role do
      before do
        @mock_client = build_mock_client
        @cmd = double
        class PluginValidateRoleTest
          include Plugin
          must_have_role "foo"        
        end
        @plugin = PluginValidateRoleTest.new 
        @plugin.client = @mock_client[:client]
        @plugin.cmd = @cmd
      end
    
      after do
        AresMUSH.send(:remove_const, :PluginValidateRoleTest)
      end
      
      it "should reject command if character doesn't have the role" do
        @mock_client[:char].should_receive(:has_any_role?).with("foo") { false }        
        @plugin.validate_has_role.should eq 'roles.permission_denied'
      end
      
      it "should accept command if character has the role" do
        @mock_client[:char].should_receive(:has_any_role?).with("foo") { true }        
        @plugin.validate_has_role.should eq nil
      end
    end
  end
end