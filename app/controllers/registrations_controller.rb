class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save

      @user.collections.create!(name: "My Collection")

      start_new_session_for @user
      redirect_to root_path, notice: "Welcome to myCards!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.expect(user: [:email_address, :password, :password_confirmation])
  end
end
