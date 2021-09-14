export IATI_DATASTORE_DATABASE_URL="postgresql://{{ postgres_user }}:{{ postgres_password }}@localhost/{{ postgres_name }}"
export SENTRY_DSN="{{ sentry_dsn }}"
export SENTRY_TRACES_SAMPLE_RATE="{{  sentry_traces_sample_rate }}"
# Disable telemetry or command can freeze on a "Y/N?" prompt
export NUXT_TELEMETRY_DISABLED=1
