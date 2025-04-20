# frozen_string_literal: true

ApiPagination.configure do |config|
  config.paginator = :kaminari

  # set this to add a header with the current page number.
  config.page_header = "X-Page"
end
