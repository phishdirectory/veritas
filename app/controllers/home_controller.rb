# frozen_string_literal: true

class HomeController < ApplicationController
  # before_action :authenticate_user
  skip_before_action :authenticate_user!, only: [:index]


  def index
  end

end
