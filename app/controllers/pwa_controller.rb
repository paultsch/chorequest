class PwaController < ApplicationController
  # PWA endpoints must be publicly accessible — skip any auth that may be
  # added to ApplicationController in the future (defensive for Turbo Native compatibility).
  skip_before_action :authenticate_user!, raise: false

  def manifest
    render formats: [:json], content_type: "application/manifest+json", layout: false
  end

  def service_worker
    # Service workers must never be aggressively HTTP-cached.
    # The browser manages its own SW update lifecycle.
    expires_now
    render layout: false
  end

  def offline
    render layout: false
  end
end
