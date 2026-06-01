#!/bin/bash
set -e

# ---------------------------------------------------------------------------
# OSC entrypoint for Keycloak
#
# Adapts Keycloak to the Eyevinn Open Source Cloud platform conventions:
#  - binds to the OSC-provided $PORT
#  - maps $OSC_HOSTNAME to the public Keycloak hostname (behind OSC's TLS proxy)
#  - parses $DATABASE_URL into Keycloak's KC_DB_* settings (optional)
#  - bootstraps the initial admin user
# ---------------------------------------------------------------------------

# --- HTTP binding -----------------------------------------------------------
# OSC provides $PORT; Keycloak terminates plain HTTP behind the platform proxy.
export KC_HTTP_PORT="${PORT:-8080}"
export KC_HTTP_ENABLED=true

# --- Section 1: DATABASE_URL parsing ---------------------------------------
# If an external database is wired in, configure Keycloak to use it.
# Otherwise Keycloak falls back to the embedded dev-file (H2) store, which is
# persisted under /opt/keycloak/data (mount a volume there for durability).
if [ -n "$DATABASE_URL" ]; then
  if [[ "$DATABASE_URL" =~ ^([^:]+)://([^:]*):?([^@]*)@([^:]+):([0-9]+)/?(.*)$ ]]; then
    DB_SCHEME="${BASH_REMATCH[1]}"
    DB_USER="${BASH_REMATCH[2]}"
    DB_PASSWORD="${BASH_REMATCH[3]}"
    DB_HOST="${BASH_REMATCH[4]}"
    DB_PORT="${BASH_REMATCH[5]}"
    DB_NAME="${BASH_REMATCH[6]}"
    export KC_DB_USERNAME="$DB_USER"
    export KC_DB_PASSWORD="$DB_PASSWORD"
    case "$DB_SCHEME" in
      "postgresql"|"postgres")
        export KC_DB=postgres
        export KC_DB_URL="jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}" ;;
      "mysql")
        export KC_DB=mysql
        export KC_DB_URL="jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_NAME}" ;;
      "mariadb")
        export KC_DB=mariadb
        export KC_DB_URL="jdbc:mariadb://${DB_HOST}:${DB_PORT}/${DB_NAME}" ;;
      *)
        echo "osc-entrypoint: unsupported DATABASE_URL scheme '$DB_SCHEME', falling back to embedded store" >&2
        export KC_DB=dev-file ;;
    esac
  else
    echo "osc-entrypoint: could not parse DATABASE_URL, falling back to embedded store" >&2
    export KC_DB=dev-file
  fi
else
  export KC_DB=dev-file
fi

# --- Section 2: OSC_HOSTNAME -> public URL ---------------------------------
# OSC terminates TLS at the edge and forwards plain HTTP with X-Forwarded-*.
if [ -n "$OSC_HOSTNAME" ]; then
  export KC_HOSTNAME="https://$OSC_HOSTNAME"
  export KC_PROXY_HEADERS=xforwarded
  export KC_HOSTNAME_STRICT=false
else
  # No public hostname (e.g. local testing): relax strict hostname checks.
  export KC_HOSTNAME_STRICT="${KC_HOSTNAME_STRICT:-false}"
fi

# --- Section 3: admin bootstrap --------------------------------------------
# Accept the historical KEYCLOAK_ADMIN* variable names and map them onto the
# current KC_BOOTSTRAP_ADMIN_* names used by Keycloak 26+.
if [ -n "$KEYCLOAK_ADMIN" ]; then
  export KC_BOOTSTRAP_ADMIN_USERNAME="$KEYCLOAK_ADMIN"
fi
if [ -n "$KEYCLOAK_ADMIN_PASSWORD" ]; then
  export KC_BOOTSTRAP_ADMIN_PASSWORD="$KEYCLOAK_ADMIN_PASSWORD"
fi
export KC_BOOTSTRAP_ADMIN_USERNAME="${KC_BOOTSTRAP_ADMIN_USERNAME:-admin}"

exec "$@"
