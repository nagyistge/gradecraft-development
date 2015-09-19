saml_settings = OneLogin::RubySaml::Settings.new

# When disabled, saml validation errors will raise an exception.
saml_settings.soft = true

# SP section
saml_settings.assertion_consumer_service_url = ENV["CONSUMER_SERVICE_URL"]
saml_settings.assertion_consumer_logout_service_url = ENV["LOGOUT_SERVICE_URL"]
saml_settings.issuer                         =  ENV["ISSUER"]
# IdP section
saml_settings.idp_entity_id                  = ENV["IDP_ENTITY_ID"]
saml_settings.idp_sso_target_url             = ENV["IDP_SSO_TARGET_URL"]
saml_settings.idp_slo_target_url             = ENV["IDP_SLO_TARGET_URL"]
saml_settings.idp_cert                       = ENV["IDP_CERT"]

# or saml_settings.idp_cert_fingerprint           = "3B:05:BE:0A:EC:84:CC:D4:75:97:B3:A2:22:AC:56:21:44:EF:59:E6"
#saml_settings.idp_cert_fingerprint_algorithm = XMLSecurity::Document::SHA1

saml_settings.name_identifier_format         = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"

# Security section
saml_settings.security[:authn_requests_signed] = false
saml_settings.security[:logout_requests_signed] = false
saml_settings.security[:logout_responses_signed] = false
saml_settings.security[:metadata_signed] = false
saml_settings.security[:digest_method] = XMLSecurity::Document::SHA1
saml_settings.security[:signature_method] = XMLSecurity::Document::RSA_SHA1

SAML_SETTINGS=saml_settings
