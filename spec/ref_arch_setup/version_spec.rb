require "spec_helper"

describe RefArchSetup::Version do
  describe "STRING" do
    it "check that STRING is set" do
      expect(RefArchSetup::Version::STRING).not_to be_empty
    end
  end
end
