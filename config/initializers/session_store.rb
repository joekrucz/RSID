# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :cookie_store, 
  key: '_blank_codebase_session',
  secure: Rails.env.production?,  # Only send cookies over HTTPS in production
  httponly: true,                 # Prevent JavaScript access to cookies
  same_site: :lax,               # CSRF protection
  expire_after: 24.hours         # Session timeout
