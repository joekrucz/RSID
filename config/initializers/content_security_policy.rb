# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :https
    # Allow @vite/client to hot reload javascript changes in development
    policy.script_src *policy.script_src, :unsafe_eval, :unsafe_inline, "http://#{ ViteRuby.config.host_with_port }" if Rails.env.development?

    # You may need to enable this in production as well depending on your setup.
    policy.script_src *policy.script_src, :blob if Rails.env.test?
    
    # Allow inline scripts in production for Inertia.js and Svelte
    # Note: unsafe_inline is ignored when nonces are present, so we need to handle this differently
    if Rails.env.production?
      policy.script_src *policy.script_src, :unsafe_inline, :unsafe_eval
    end

    policy.style_src   :self, :https
    # Allow @vite/client to hot reload style changes in development
    policy.style_src *policy.style_src, :unsafe_inline if Rails.env.development?
    
    # Allow inline styles in production for Inertia.js and Svelte
    if Rails.env.production?
      policy.style_src *policy.style_src, :unsafe_inline
    end

    # Allow WebSocket connections to Vite dev server
    policy.connect_src :self, :https
    policy.connect_src *policy.connect_src, "http://#{ ViteRuby.config.host_with_port }", "ws://#{ ViteRuby.config.host_with_port }" if Rails.env.development?

    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  # Disable nonces in both development and production to allow unsafe_inline to work
  config.content_security_policy_nonce_generator = nil
  config.content_security_policy_nonce_directives = []

  # Report violations without enforcing the policy.
  # config.content_security_policy_report_only = true
end
