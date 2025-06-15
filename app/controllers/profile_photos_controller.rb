# frozen_string_literal: true

class ProfilePhotosController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    user = User.find_by(pd_id: params[:pd_id])

    unless user
      head :not_found
      return
    end

    unless user.has_profile_photo?
      redirect_to action: :initials, pd_id: params[:pd_id]
      return
    end

    # Set appropriate cache headers for profile photos
    expires_in 1.hour, public: true

    # Serve the profile photo
    redirect_to rails_blob_path(user.profile_photo, disposition: "inline"), allow_other_host: false
  end

  def avatar
    user = User.find_by(pd_id: params[:pd_id])
    variant = params[:variant]&.to_sym || :thumb

    unless user
      head :not_found
      return
    end

    unless user.has_profile_photo?
      redirect_to action: :initials, pd_id: params[:pd_id], variant: variant
      return
    end

    # Set appropriate cache headers
    expires_in 1.hour, public: true

    # Serve the variant
    case variant
    when :thumb
      redirect_to rails_representation_path(user.profile_photo.variant(resize_to_limit: [100, 100]), disposition: "inline")
    when :medium
      redirect_to rails_representation_path(user.profile_photo.variant(resize_to_limit: [200, 200]), disposition: "inline")
    when :large
      redirect_to rails_representation_path(user.profile_photo.variant(resize_to_limit: [400, 400]), disposition: "inline")
    else
      redirect_to rails_blob_path(user.profile_photo, disposition: "inline")
    end
  end

  def avatar_square
    user = User.find_by(pd_id: params[:pd_id])
    variant = params[:variant]&.to_sym || :thumb

    unless user
      head :not_found
      return
    end

    unless user.has_profile_photo?
      redirect_to action: :initials, pd_id: params[:pd_id], variant: variant
      return
    end

    # Set appropriate cache headers
    expires_in 1.hour, public: true

    # Serve the square variant (same as regular avatar)
    case variant
    when :thumb
      redirect_to rails_representation_path(user.profile_photo.variant(resize_to_limit: [100, 100]), disposition: "inline")
    when :medium
      redirect_to rails_representation_path(user.profile_photo.variant(resize_to_limit: [200, 200]), disposition: "inline")
    when :large
      redirect_to rails_representation_path(user.profile_photo.variant(resize_to_limit: [400, 400]), disposition: "inline")
    else
      redirect_to rails_blob_path(user.profile_photo, disposition: "inline")
    end
  end

  def avatar_circle
    user = User.find_by(pd_id: params[:pd_id])
    variant = params[:variant]&.to_sym || :thumb

    unless user
      head :not_found
      return
    end

    unless user.has_profile_photo?
      redirect_to action: :initials_circle, pd_id: params[:pd_id], variant: variant
      return
    end

    # Set appropriate cache headers
    expires_in 1.hour, public: true

    # Serve the circle variant with mask applied
    size = case variant
           when :thumb then 100
           when :medium then 200
           when :large then 400
           else 200
           end

    # Generate masked image and serve as PNG
    masked_image = generate_circle_masked_image(user.profile_photo, size)

    if masked_image
      respond_to do |format|
        format.png {
          send_data masked_image,
                    type: "image/png",
                    disposition: "inline",
                    filename: "#{user.pd_id}_circle_#{variant}.png"
        }
      end
    else
      # Fallback to square version if circle processing fails
      redirect_to action: :avatar_square, pd_id: params[:pd_id], variant: variant
    end
  end

  def initials
    user = User.find_by(pd_id: params[:pd_id])
    variant = params[:variant]&.to_sym || :medium

    unless user
      head :not_found
      return
    end

    # Set size based on variant
    size = case variant
           when :thumb then 100
           when :medium then 200
           when :large then 400
           else 200
           end

    # Generate a consistent color based on user ID
    color_hue = user.pd_id.bytes.sum % 360

    # Set appropriate cache headers
    expires_in 1.day, public: true

    svg_content = generate_initials_svg(user.initials, size, color_hue, circle_clip: false)

    respond_to do |format|
      format.svg { render xml: svg_content, content_type: "image/svg+xml" }
    end
  end

  def initials_circle
    user = User.find_by(pd_id: params[:pd_id])
    variant = params[:variant]&.to_sym || :medium

    unless user
      head :not_found
      return
    end

    # Set size based on variant
    size = case variant
           when :thumb then 100
           when :medium then 200
           when :large then 400
           else 200
           end

    # Generate a consistent color based on user ID
    color_hue = user.pd_id.bytes.sum % 360

    # Set appropriate cache headers
    expires_in 1.day, public: true

    svg_content = generate_initials_svg(user.initials, size, color_hue, circle_clip: true)

    respond_to do |format|
      format.svg { render xml: svg_content, content_type: "image/svg+xml" }
    end
  end

  private

  def generate_initials_svg(initials, size, color_hue, circle_clip: false)
    # Generate consistent colors
    bg_color = "hsl(#{color_hue}, 65%, 55%)"
    text_color = "#ffffff"
    font_size = size * 0.4
    center = size / 2.0

    clip_path = if circle_clip
                  "<defs><clipPath id=\"circle-clip\"><circle cx=\"#{center}\" cy=\"#{center}\" r=\"#{center}\"/></clipPath></defs>"
                else
                  ""
                end

    group_clip = circle_clip ? " clip-path=\"url(#circle-clip)\"" : ""

    <<~SVG
      <svg width="#{size}" height="#{size}" xmlns="http://www.w3.org/2000/svg">
        #{clip_path}
        <g#{group_clip}>
          <rect width="#{size}" height="#{size}" fill="#{bg_color}"/>
          <text x="#{center}" y="#{center}"
                font-family="system-ui, -apple-system, BlinkMacSystemFont, sans-serif"
                font-size="#{font_size}"
                font-weight="600"
                fill="#{text_color}"
                text-anchor="middle"
                dominant-baseline="central">#{initials.upcase}</text>
        </g>
      </svg>
    SVG
  end

  def generate_circle_masked_image(attachment, size)
    require "mini_magick"

    # Download and resize the image
    image = MiniMagick::Image.read(attachment.download)
    image.resize "#{size}x#{size}^"
    image.gravity "center"
    image.crop "#{size}x#{size}+0+0"

    # Create a circular mask
    mask = MiniMagick::Image.open("canvas:black")
    mask.size "#{size}x#{size}"
    mask.format "png"

    # Draw white circle on black background for mask
    mask.combine_options do |c|
      c.fill "white"
      c.draw "circle #{size / 2},#{size / 2} #{size / 2},#{size / 4}"
    end

    # Apply the mask to create circular image
    image.format "png"
    image.composite(mask) do |c|
      c.alpha "set"
      c.compose "dst_in"
    end

    image.to_blob
  rescue => e
    # Fallback to redirect if image processing fails
    Rails.logger.error "Circle image generation failed: #{e.message}"
    nil
  end

end
