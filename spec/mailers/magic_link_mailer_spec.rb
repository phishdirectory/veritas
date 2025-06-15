require "rails_helper"

RSpec.describe MagicLinkMailer, type: :mailer do
  describe "login_link" do
    let(:mail) { MagicLinkMailer.login_link }

    it "renders the headers" do
      expect(mail.subject).to eq("Login link")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

end
