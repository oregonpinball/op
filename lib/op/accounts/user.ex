defmodule OP.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias OP.Players.Player

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :utc_datetime
    field :authenticated_at, :utc_datetime, virtual: true

    field :role, Ecto.Enum,
      values: [:system_admin, :td, :player],
      default: :player

    has_one :player, Player

    timestamps(type: :utc_datetime)
  end

  @doc """
  A generic changeset for updating user fields.

  This changeset allows updates to all non-sensitive fields. For email or
  password updates, use the specific `email_changeset/3` or `password_changeset/3` functions.
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :role, :confirmed_at])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
      message: "must have the @ sign and no spaces"
    )
    |> validate_length(:email, max: 160)
    |> unique_constraint(:email)
  end

  @doc """
  A user changeset for registering or changing the email.

  It requires the email to change otherwise an error is added.

  ## Options

    * `:validate_unique` - Set to false if you don't want to validate the
      uniqueness of the email, useful when displaying live validations.
      Defaults to `true`.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
  end

  defp validate_email(changeset, opts) do
    changeset =
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
        message: "must have the @ sign and no spaces"
      )
      |> validate_length(:email, max: 160)

    if Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:email, OP.Repo)
      |> unique_constraint(:email)
      |> validate_email_changed()
    else
      changeset
    end
  end

  defp validate_email_changed(changeset) do
    if get_field(changeset, :email) && get_change(changeset, :email) == nil do
      add_error(changeset, :email, "did not change")
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the password.

  It is important to validate the length of the password, as long passwords may
  be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%OP.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  A user changeset for admin-created users.

  Creates a user with email, password, and role. The user is auto-confirmed
  so they can log in immediately.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database. Set to `false` for live validation. Defaults to `true`.
  """
  def admin_creation_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :role])
    |> validate_required([:email, :password, :role])
    |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
      message: "must have the @ sign and no spaces"
    )
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, OP.Repo)
    |> unique_constraint(:email)
    |> validate_inclusion(:role, [:system_admin, :td, :player])
    |> validate_length(:password, min: 8, max: 72)
    |> maybe_hash_password(opts)
    |> maybe_set_confirmed_at(opts)
  end

  defp maybe_set_confirmed_at(changeset, opts) do
    if Keyword.get(opts, :hash_password, true) && changeset.valid? do
      put_change(changeset, :confirmed_at, DateTime.utc_now(:second))
    else
      changeset
    end
  end

  @doc """
  A user changeset for creating an invited user.

  Validates email and role only. The user is created without a password
  or confirmation -- they will set their password via the invitation link.
  """
  def invitation_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :role])
    |> validate_required([:email, :role])
    |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
      message: "must have the @ sign and no spaces"
    )
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, OP.Repo)
    |> unique_constraint(:email)
    |> validate_inclusion(:role, [:system_admin, :td, :player])
  end

  @doc """
  A user changeset for changing the role.

  Prevents system admins from demoting themselves.
  """
  def role_changeset(user, attrs, current_user_id) do
    changeset =
      user
      |> cast(attrs, [:role])
      |> validate_required([:role])
      |> validate_inclusion(:role, [:system_admin, :td, :player])

    # Prevent self-demotion for system admins
    if user.id == current_user_id && user.role == :system_admin &&
         get_change(changeset, :role) != :system_admin do
      add_error(changeset, :role, "cannot demote yourself")
    else
      changeset
    end
  end
end
