# ExGoogleRecaptcha

An Elixir library for integrating with Google reCAPTCHA Enterprise.

## Installation

Add `ex_google_recaptcha` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_google_recaptcha, "~> 0.1.0"} # Replace with the actual version
  ]
end
```

Then, run:

```bash
mix deps.get
```

## Configuration

You need to configure your Google reCAPTCHA Enterprise credentials in your `config/config.exs` or an environment-specific configuration file (e.g., `config/prod.exs`). For example:

```elixir
use Mix.Config

config :ex_google_recaptcha,
  project_id: "your-google-cloud-project-id",
  site_key: "your-recaptcha-site-key",
  secret: "your-recaptcha-api-key"
```

> **Note:**
>
> - **project_id:** Your Google Cloud Project ID.
> - **site_key:** The site key for your reCAPTCHA Enterprise instance.
> - **secret:** Your reCAPTCHA Enterprise API key (the secret key).

## Usage

### 1. Include the JavaScript

In your Phoenix template (e.g., `form.html.heex`), include the reCAPTCHA Enterprise JavaScript:

```html
<script src="<%= ExGoogleRecaptcha.script() %>"></script>
```

This loads the necessary JavaScript from Google's servers. Ensure that this script is loaded before your form.

### 2. Add the Hook to Your Form

To automatically handle reCAPTCHA token generation on form submit, you can use the provided LiveView Hook.

#### a. Generate the Hook File

Run the following command to generate the hook file:

```bash
mix ex_google_recaptcha.gen.hook
```

This creates `ex_google_recaptcha.js` in `assets/js/hooks`. Ensure that the `assets/js` directory exists in your project.

#### b. Import and Register the Hook

In your `assets/js/app.js` (or your application's main JavaScript file), import and register the hook:

```js
import RecaptchaHook from "/assets/js/hooks/ex_google_recaptcha.js";

let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: {
    RecaptchaHook: RecaptchaHook,
    // ... other hooks
  },
});
```

#### c. Add Attributes to Your Form

In your form, add the `phx-hook` and `data-site-key` attributes:

```html
<form
  phx-submit="your_form_event"
  phx-hook="RecaptchaHook"
  data-site-key="<%= ExGoogleRecaptcha.site_key() %>"
>
  <button type="submit">Submit</button>
</form>
```

- **phx-hook="RecaptchaHook":** Attaches the LiveView hook to the form.
- **data-site-key:** Provides your reCAPTCHA site key to the JavaScript hook.

### 3. Verify the Token

In your LiveView, use `ExGoogleRecaptcha.verify/1` to verify the reCAPTCHA token.

#### a. Handling Valid Tokens

```elixir
def handle_event("your_form_event", %{"g-recaptcha-response" => token}, socket) do
  case ExGoogleRecaptcha.verify(token) do
    {:ok, score} ->
      # The token is valid.
      # Use the score (0.0 to 1.0) to decide how to proceed (e.g., allow login, require further verification).
      IO.puts("reCAPTCHA score: #{score}")
      # ... your logic ...
      {:noreply, socket}

    {:error, reason} ->
      # The token is invalid. Show an error message to the user.
      IO.puts("reCAPTCHA verification failed: #{reason}")
      # ... your error handling ...
      {:noreply, socket}

    {:error, other} ->
      IO.puts("reCAPTCHA verification error: #{inspect(other)}")
      {:noreply, socket}
  end
end
```

#### b. Handling Missing Tokens

```elixir
def handle_event("your_form_event", _params, socket) do
  # g-recaptcha-response is nil
  case ExGoogleRecaptcha.verify(nil) do
    {:error, :missing_token} ->
      IO.puts("g-recaptcha-response is nil")
      {:noreply, socket}
  end
end
```

## Explanation

- **ExGoogleRecaptcha.script/0:** Returns the URL for the reCAPTCHA Enterprise JavaScript.
- **ExGoogleRecaptcha.site_key/0:** Fetches the reCAPTCHA site key from your application's configuration.
- **ExGoogleRecaptcha.verify/1:** Verifies the reCAPTCHA token with Google's servers.
  - Takes the token string as an argument.
  - Returns `{:ok, score}` if the token is valid, where `score` is a float between `0.0` and `1.0` indicating the likelihood that the user is a bot.
  - Returns `{:error, reason}` if the token is invalid, where `reason` is a string describing the error.
  - Returns `{:error, other}` if there is an unexpected error, with `other` containing the error details.

The Mix task `mix ex_google_recaptcha.gen.hook` generates the JavaScript file `ex_google_recaptcha.js` containing the LiveView hook, which automatically handles the reCAPTCHA token generation when the form is submitted.

## Dependencies

- **Finch:** For making HTTP requests to the reCAPTCHA Enterprise API. (Ensure Finch is correctly set up in your project.)
- **Jason:** For encoding and decoding JSON.

## JavaScript Hook Details

The generated `ex_google_recaptcha.js` hook performs the following actions:

- On the mounted lifecycle event, it attaches an event listener to the form.
- On form submit, it prevents the default form submission.
- Calls `grecaptcha.enterprise.ready` to ensure the reCAPTCHA API is loaded.
- Calls `grecaptcha.enterprise.execute` to retrieve a token.
- Creates a hidden input field named `g-recaptcha-response` and sets its value to the token.
- Appends the hidden input to the form and submits the form.
