# Seculate Admin

Staff dashboard for the Seculate marketplace. Static HTML and ES modules, no build step.

## Layout
- `index.html`, `css/`, `js/` — the app (`js/core` shared code, `js/views` one file per screen)
- `database/001_admin_rpcs.sql` — server-side functions the dashboard calls (run once in the SQL editor)
- `bootstrap_super_admin.sql` — creates the first super admin
- `vercel.json` — security headers and content security policy

## Security model
- Staff sign in with email and password, must change a temporary password, and must pass authenticator-app (TOTP) 2-step verification.
- The browser only holds the public publishable key. All data access is enforced on the server by row-level security and by functions that check a role permission **and** a 2-step-verified session. Changing the page code cannot widen access.
- Reading private chats requires a written reason; every sensitive read, export and change is written to the audit log.
- Sessions end after 30 minutes without activity.
- No secrets belong in this repository.

## Deploy
Vercel project `seculate-admin` is linked to this repo with Root Directory `admin` (framework: Other, no build command, output directory `.`). Pushes to the production branch deploy automatically; add the domain under Project → Domains.
