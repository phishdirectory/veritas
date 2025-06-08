# frozen_string_literal: true

class WellKnownController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    path = params[:path]

    # Security: only allow specific well-known paths
    allowed_paths = %w[
      security.txt
      robots.txt
      sitemap.xml
      apple-app-site-association
      assetlinks.json
      webfinger
      nodeinfo
      host-meta
    ]

    unless allowed_paths.include?(path)
      render plain: "Not Found", status: :not_found
      return
    end

    # Try to find the file in the well-known directory
    file_path = Rails.root.join("public", ".well-known", path)

    if File.exist?(file_path)
      content_type = case File.extname(path)
                     when ".json"
                       "application/json"
                     when ".xml"
                       "application/xml"
                     when ".txt"
                       "text/plain"
                     else
                       "text/plain"
                     end

      send_file file_path, type: content_type, disposition: "inline"
    else
      render plain: "Not Found", status: :not_found
    end
  end

end
