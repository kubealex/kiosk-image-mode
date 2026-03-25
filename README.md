# kiosk-base

A RHEL bootc base image for kiosk applications built on GNOME.

## Repository structure

```
.
├── Dockerfile
├── etc/                          # /etc overlay — copied verbatim into the image
│   ├── dconf/
│   │   ├── profile/
│   │   │   └── user              # dconf profile: user-db + system-db:local
│   │   └── db/
│   │       └── local.d/
│   │           ├── 01-dash-to-dock   # Disable overview on startup
│   │           ├── 02-power-saving   # Disable screen lock and idle timeout
│   │           └── 03-extensions     # Enable dash-to-dock extension
│   ├── gdm/
│   │   └── custom.conf           # GDM autologin for 'redhat' user
│   ├── ostree/
│   │   └── auth.json             # ⚠ Container registry credentials (see below)
│   ├── rhc/
│   │   └── .rhc_connect_credentials  # ⚠ Red Hat Insights credentials (see below)
│   └── sudoers.d/
│       └── wheel-sudo            # Passwordless sudo for wheel group
└── usr/                          # /usr overlay — copied verbatim into the image
    ├── lib/
    │   ├── systemd/system/
    │   │   └── rhc-connect.service   # One-shot Insights registration service
    │   └── tmpfiles.d/
    │       └── dash-to-dock.conf     # Provisions extension into user profile at boot
    └── share/
        └── gdm/
            └── monitors.xml      # Default display resolution (800x600 for QEMU)
```

## Before building

### 1. Container registry credentials (`etc/ostree/auth.json`)

Populate with credentials for GHCR (or any other registry your kiosk image pulls from):

```json
{
  "auths": {
    "ghcr.io": {
      "auth": "<base64-encoded user:token>"
    }
  }
}
```

You can use Podman to generate the auth.json file:

```bash
podman login ghcr.io --authfile etc/ostree/auth.json
```

### 2. Red Hat Insights credentials (`etc/rhc/.rhc_connect_credentials`)

```bash
RHC_ACT_KEY=<activation-key>
RHC_ORG_ID=<org-id>
```

Activation keys can be created at:
https://console.redhat.com/insights/connector/activation-keys

> **Note:** Both files above contain secrets and must **not** be committed to a
> public repository. Add them to `.gitignore` and inject them at build time via
> a secrets manager or CI/CD pipeline.

## Building

```bash
podman build -t kiosk-base .
```

## Display resolution

The default `monitors.xml` targets an 800×600 QEMU VM. For physical kiosk
hardware, update `usr/share/gdm/monitors.xml` with the correct connector name,
resolution, and refresh rate before building.

## Extending

To add new `/etc/` configuration, drop files under `etc/` following the same
directory structure. The single `COPY etc/ /etc/` in the Dockerfile will pick
them up automatically on the next build — no Dockerfile changes required.

Similarly, new systemd units or tmpfiles rules go under `usr/lib/systemd/system/`
and `usr/lib/tmpfiles.d/` respectively.
