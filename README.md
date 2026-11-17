# Salar VPN — Public Bootstrap

> **Preview 0.1.0**: Not yet validated for production or real payments.

This public repository contains only the safe bootstrapper, README and managed-files manifest.
The application source and private installer live in `Salarsdg/salar-app` (**private**).

## First-time setup

Review the installer first, then on a supported Ubuntu/Debian VPS run:

```bash
curl -fsSL https://raw.githubusercontent.com/Salarsdg/salar-bootstrap/main/bootstrap.sh -o /tmp/salar-bootstrap.sh
less /tmp/salar-bootstrap.sh
sudo bash /tmp/salar-bootstrap.sh
```

The bootstrap script asks for the private repository `Salarsdg/salar-app`,
the Git ref (default `main`), and a **separate**, short-lived,
**read-only** token scoped to that private repository. Do not reuse the publisher PAT on the VPS.

The current installer deploys only one shop plus license server; multi-tenant SaaS,
web-based restore/update, and live payments still require development and validation.
