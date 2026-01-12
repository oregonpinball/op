defmodule OPWeb.Storybook do
  use PhoenixStorybook,
    otp_app: :op,
    content_path: Path.expand("../../storybook", __DIR__),
    # assets path are remote path, not local file-system paths
    css_path: "/assets/css/app.css",
    color_mode: true,
    color_mode_sandbox_dark_class: "dark",
    sandbox_class: "op-storybook-sandbox"
end
