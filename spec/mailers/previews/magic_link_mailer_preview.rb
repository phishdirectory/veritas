# Preview all emails at http://localhost:3000/rails/mailers/magic_link_mailer
class MagicLinkMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/magic_link_mailer/login_link
  def login_link
    MagicLinkMailer.login_link
  end

end
