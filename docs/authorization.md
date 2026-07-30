# Who can see which projects

This document is about **authorization** — what a signed-in user is allowed to
touch. For getting people signed in at all, see
[authentication.md](authentication.md).

**None of this applies while single sign-on is off.** That is the default and a
supported configuration: with no identity provider there is no identity to
compare a project against, so every project stays visible and editable by
everybody, exactly as it was before any of this existed. Everything below
describes what changes when you switch sign-in on.

## The rule

With sign-in enforced, a user may see and change a project when **any** of these
is true:

| | Who | Why |
| --- | --- | --- |
| 1 | They are an **administrator** | Somebody has to be able to clean up after a person who has left. Administrators are the addresses in the admin list — the same ones who can open Settings without the password. |
| 2 | They **own** it | Ownership is stamped at creation and never changes by itself. |
| 3 | It is **unowned** | See the next section. This is the one that surprises people. |
| 4 | Their **department** matches | Not reachable yet. See "Departments" below. |

Otherwise the project does not appear in their list, and opening it directly
fails with *"You do not have access to this project"*.

There is no read-only middle ground. If you can see a project you can change it,
including deleting it and running mipgen on it. Anything more granular is not
built.

## Projects that already exist: they stay shared

`owner` is only stamped when a project is created **while sign-in is enforced**.
That means:

- Every project created before you upgraded to this version is **unowned**.
- Every project created while sign-in was switched off is **unowned**.
- Unowned projects stay visible and editable by **everyone who signs in**.

This is deliberate. The alternative — hiding unowned projects from everybody but
administrators — means that the moment an administrator switches sign-in on, every
user opens FLUMIP and finds their work gone. That looks exactly like data loss and
it generates exactly one kind of support request. Nothing disappears here.

The practical consequence is that **switching sign-in on does not retroactively
partition existing work.** Isolation begins with the projects created afterwards,
and the unowned set only ever shrinks. If you need the old projects partitioned
too, an administrator has to assign owners:

```sql
-- Find the flumip_user id for the person, then claim their projects.
SELECT id, email FROM flumip_user ORDER BY id;
UPDATE project SET "owner" = <user id> WHERE id IN (<project ids>);
```

There is no user interface for reassigning ownership. That is a genuine gap, not
an oversight of this document.

## What happens when a user is deleted

Their projects become **unowned**, not deleted — the foreign key is
`ON DELETE SET NULL`. Deleting an identity must not delete the data that identity
produced. The projects fall back to being shared, and an administrator can
reassign them.

## Departments

`Project.department` exists, the access rule reads it, and **it can never
match**, because nothing ever sets a user's department: FLUMIP collects no
department claim from your identity provider.

This is a deliberate half-measure rather than an accident. The rule is written
with the department clause in place so that switching it on later is a change to
sign-in plus one Settings field, instead of a change to every place that guards a
project. Until somebody does that, department-based sharing does not work and you
should ignore the field.

If you are reading this because you want it: what is missing is a configurable
claim name, reading that claim at sign-in, storing it on `flumip_user`, and
copying it onto new projects.

## The UCSC track URL is a separate matter

"Open in UCSC Track browser" builds a URL like:

```
https://<your FLUMIP host>/ucsc_track/019637f2-...-a1b2c3d4e5f6
```

and hands it to genome.ucsc.edu, which fetches it **as an anonymous third party**.
It sends no session and no credentials, and there is nowhere for it to sign in. So
this one URL is necessarily reachable without authentication.

What protects it is that the path is an unguessable per-project token rather than
the project's number. Earlier versions used `/ucsc_track/1`, `/ucsc_track/2` and so
on, which meant anyone who could reach the server could read every project's track
by counting. The token is only ever handed out to somebody allowed to open the
project.

Two things follow:

- **Treat that URL as a shared secret.** Anyone who has it can read that one
  project's BED track — nothing else, but that much. It is safe to paste into
  UCSC; it is not safe to post in a public issue tracker.
- **To rotate it**, clear the token; the next time the owner opens UCSC a new one
  is minted and the old URL stops working.

  ```sql
  UPDATE project SET "trackToken" = NULL WHERE id = <project id>;
  ```

Anything you pasted into UCSC from a version before this change will have stopped
working, because those URLs used the project id. Re-open the project and use the
button again.

## Administrators

Administrator is not a stored role — it is recomputed from the admin email list
**at sign-in**. So adding somebody to the list takes effect the next time they
sign in, not immediately, and removing somebody leaves their current session
administrative until it expires or they sign out.

### Removing someone's access immediately

Use the application's own sign-out. That drops the cached credential in the same
step, so the change takes effect on the person's very next request.

**Deleting rows in SQL does not have the same effect**, and this is worth knowing
before you rely on it in an emergency. Deleting from `auth_session` does remove
the bearer tokens — the cascade works — but the server keeps a short-lived cache
of already-issued tokens, and only its own revocation path clears it. Verified
against a running server: after `DELETE FROM auth_session`, the user's requests
still succeeded. Access ends when the cached token expires, which is **up to 30
minutes**.

So, in order of preference:

1. Have the person sign out, or sign them out from the application.
2. If you must act out of band and cannot wait up to 30 minutes, restart the
   service — the cache is in memory and does not survive it. Sessions themselves
   live in Postgres, so a restart does *not* sign everybody else out.
3. `DELETE FROM auth_session ...` alone is fine when a delay is acceptable.

## Troubleshooting

**"You do not have access to this project" on a project I definitely own.**
Ownership is by `flumip_user` row, and a row is per identity provider (`issuer` +
`subject`). If the install was moved to a different provider, the same person
signing in gets a *new* row, and their old projects still point at the old one.
Check:

```sql
SELECT id, email, issuer, subject FROM flumip_user WHERE email = '<address>';
```

Two rows for one address means exactly that. Repoint the projects at the new id.

**A project vanished from my list after sign-in was switched on.** It has an
owner and it is not you. Unowned projects never vanish, so this project was
created by somebody signed in as somebody else. An administrator can see it.

**Everyone can still see everything.** Sign-in is probably not actually being
enforced — that is a separate condition with its own failure modes, all of them
fail-open by design. See "Why sign-in might not be enforced" in
[authentication.md](authentication.md).

**A user left and their projects are gone.** They are not gone. If the identity
was deleted the projects became unowned, which means *more* visible, not less.
Look for them in any user's list.
