defmodule Investing.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Comeonin.Argon2


  schema "users" do
    field :email, :string
    field :password_hash, :string
    field :username, :string
    field :balance, :float
    ## Virtual Fields ##
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

    has_many :assets, Investing.Finance.Asset
    has_many :alerts, Investing.Finance.Alert
    has_many :orders, Investing.Finance.Order
    has_many :holdings, Investing.Finance.Holding

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :password, :balance])
    |> validate_required([:username, :email, :password])
    |> unique_constraint(:email)
    |> validate_format(:email, ~r/@/)
    |> validate_length(:password, min: 6)
    |> validate_confirmation(:password)
    |> unique_constraint(:username)
    |> downcase_email
    |> encrypt_password
  end


  ## Encrypt the password
  def encrypt_password(changeset) do
    password = get_change(changeset, :password)
    if password do
      password = hash_password(password)
      put_change(changeset, :password_hash, password)
    else
      changeset
    end
  end

  ## Change all email letters to lowercases
  def downcase_email(changeset) do
    update_change(changeset, :email, &String.downcase/1)
  end

  ## help methods
  def hash_password(password) do
    Argon2.hashpwsalt(password)
  end

  def validate_password(password, hash) do
    Argon2.checkpw(password, hash)
  end

end
