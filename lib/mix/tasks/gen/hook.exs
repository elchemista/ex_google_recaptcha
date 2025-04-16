defmodule Mix.Tasks.Gen.Hook do
  use Mix.Task

  @shortdoc "Generates the ex_google_recaptcha.js hook file"
  def run(_) do
    target_dir = Path.join(Mix.cwd!(), "assets", "js", "hooks")
    target_file = Path.join(target_dir, "ex_google_recaptcha.js")

    file_content = """
    const RecaptchaHook = {
        mounted() {
            grecaptcha.enterprise.ready(() => {
                // Get the site key from the data attribute
                let siteKey = this.el.dataset.siteKey;

                grecaptcha.enterprise.execute(siteKey, { action: "submit" })
                    .then((token) => {
                        let input = document.createElement("input");
                        input.type = "hidden";
                        input.name = "g-recaptcha-response";
                        input.value = token;
                        this.el.appendChild(input);
                    });
            });

            this.el.addEventListener("submit", (event) => {
                // Prevent immediate submission
                event.preventDefault();

                // Wait for reCAPTCHA Enterprise to be ready
                grecaptcha.enterprise.ready(() => {
                    // Get the site key from the data attribute
                    let siteKey = this.el.dataset.siteKey;

                    grecaptcha.enterprise.execute(siteKey, { action: "submit" })
                        .then((token) => {
                            let input = this.el.querySelector(
                                "input[name='g-recaptcha-response']",
                            );
                            if (!input) {
                                // Create a hidden input to hold the reCAPTCHA token
                                input = document.createElement("input");
                                input.type = "hidden";
                                input.name = "g-recaptcha-response";
                                input.value = token;
                                this.el.appendChild(input);

                                this.fireEvent(
                                    event.originalEvent.eventType,
                                    event.originalEvent,
                                );

                                return;
                            }

                            input.value = token;

                            this.fireEvent(
                                event.originalEvent.eventType,
                                event.originalEvent,
                            );
                        });
                });
            });
        },
    };

    export default RecaptchaHook;
    """

    # Check if the assets/js directory exists.  If not, we error.
    assets_js_dir = Path.join(Mix.cwd!(), "assets", "js")

    if !File.dir?(assets_js_dir) do
      IO.puts(:stderr, "Error: assets/js directory does not exist.  Please create it first.")
      # Use System.halt for a non-zero exit code
      System.halt(1)
    end

    # Create the hooks directory if it doesn't exist.
    if !File.dir?(target_dir) do
      File.mkdir_p!(target_dir)
      IO.puts("Created directory: #{target_dir}")
    end

    # Write the file.
    File.write!(target_file, file_content)
    IO.puts("Generated file: #{target_file}")
  end
end
