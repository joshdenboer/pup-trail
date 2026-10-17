# Pup Trail

A dog-rescue trail adventure for kids, designed by a 9-year-old and her dad. Oregon Trail meets a dog shelter, with school work hidden inside trail problems.

- `index.html` — the kids' game (login with family code + name + PIN)
- `parent.html` — parent dashboard (accounts, kids, invites, activity, chat log)
- `shared.js` — breeds, worlds, items, avatar pieces, question generator
- `sql/001_schema.sql` — Supabase schema, RLS and RPCs (run once in the SQL editor)
- `config.js` — Supabase URL + anon key
- `assets/` — Higgsfield-generated art, web-sized

## Setup
1. Create a new Supabase project. In the SQL editor, run `sql/001_schema.sql`.
2. In Authentication → Providers, keep Email enabled. (Optional: turn off "Confirm email" for faster parent sign-up.)
3. Copy the project URL and anon key into `config.js`.
4. Host the folder as a static site (GitHub Pages from `main` works).
5. Open `parent.html`, create your parent account and family, add kids, share the family code.
