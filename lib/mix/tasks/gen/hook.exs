defmodule Mix.Tasks.Gen.Hook do
  use Mix.Task

  @shortdoc "Generates the ex_google_recaptcha.js hook file"
  def run(_) do
    target_dir = Path.join(Mix.cwd!(), "assets", "js", "hooks")
    target_file = Path.join(target_dir, "ex_google_recaptcha.js")

    file_content = """
    const RecaptchaHook = {
    mounted() {
        const form = this.el;

        form.addEventListener("submit", (event) => {
            if (event._captchaDone) return;

            event.preventDefault();
            event.stopImmediatePropagation();

            grecaptcha.enterprise.ready(() => {
                const siteKey = form.dataset.siteKey;
                grecaptcha.enterprise
                    .execute(siteKey, { action: "submit" })
                    .then((token) => {
                        let input = form.querySelector(
                            "input[name='g-recaptcha-response']",
                        );
                        if (!input) {
                            input = document.createElement("input");
                            input.type = "hidden";
                            input.name = "g-recaptcha-response";
                            form.appendChild(input);
                        }
                        input.value = token;

                        const synthetic = new Event("submit", {
                            bubbles: true,
                            cancelable: true,
                        });
                        synthetic._captchaDone = true;
                        form.dispatchEvent(synthetic);
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
