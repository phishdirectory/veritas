# frozen_string_literal: true

Rails.application.configure do
  console do
    PaperTrail.request.whodunnit = -> {
      @paper_trail_whodunnit ||= begin
        user = nil
        until user.present?
          print "What is your email (used by PaperTrail to record who changed records)? "
          email = gets.chomp
          user = User.find_by(email:)
        end
        puts "Thank you, #{user.name}! Have a wonderful time!"
        user.id
      end
    }
  end
end

# Trying to update a bunch of records and need to change the edit history per record? Try this out:

# PaperTrail.request(whodunnit: 'Dorian Marié') do
#   widget.update name: 'Wibble'
# end

# See https://github.com/paper-trail-gem/paper_trail#setting-whodunnit-temporarily for more details
