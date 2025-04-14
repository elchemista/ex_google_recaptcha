defmodule ExGoogleRecaptcha do
  @moduledoc """
  Documentation for `ExGoogleRecaptcha`.
  """

  def script, do: "https://www.google.com/recaptcha/enterprise.js?render=" <> site_key()

  def site_key, do: Application.fetch_env!(:ex_google_recaptcha, :site_key)

  def verify(nil), do: {:error, :missing_token}

  def verify(token) when is_bitstring(token) do
    project_id = Application.fetch_env!(:ex_google_recaptcha, :project_id)
    api_key = Application.fetch_env!(:ex_google_recaptcha, :secret)
    site_key = Application.fetch_env!(:ex_google_recaptcha, :site_key)

    url =
      "https://recaptchaenterprise.googleapis.com/v1/projects/" <>
        "#{project_id}/assessments?key=#{api_key}"

    body = %{
      "event" => %{
        "token" => token,
        "siteKey" => site_key,
        "expectedAction" => "submit"
      }
    }

    headers = [{"Content-Type", "application/json"}]

    case Finch.build(:post, url, headers, Jason.encode!(body))
         |> Finch.request(Finch) do
      {:ok, %Finch.Response{status: 200, body: raw_body}} ->
        parse_enterprise_response(raw_body)

      error ->
        {:error, error}
    end
  end

  defp parse_enterprise_response(raw_body) do
    case Jason.decode(raw_body) do
      {:ok,
       %{
         "tokenProperties" => %{"valid" => true},
         "riskAnalysis" => %{"score" => score}
       }} ->
        {:ok, score}

      {:ok,
       %{
         "tokenProperties" => %{"valid" => false, "invalidReason" => reason}
       }} ->
        {:error, reason}

      {:ok, other} ->
        {:error, other}

      error ->
        {:error, error}
    end
  end
end
