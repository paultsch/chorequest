class PwaController < ApplicationController
  # PWA endpoints must be publicly accessible — skip any auth that may be
  # added to ApplicationController in the future (defensive for Turbo Native compatibility).
  skip_before_action :authenticate_user!, raise: false

  # The service worker JS is fetched by the browser without a CSRF token,
  # which trips Rails' cross-origin JS protection. Safe to skip — the SW
  # URL is same-origin and this is a read-only GET request.
  protect_from_forgery except: [:service_worker]

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
