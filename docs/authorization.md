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
| 4 | Their **department** matches | Only when a department claim is configured. See "Departments" below. |

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
too, an administrator assigns owners: expand the project's tile and pick the
owner from the **Owner** list, which offers everybody who has signed in at least
once. **Unowned — shared with everyone** releases a project again. Only
administrators see that list; an owner cannot give a project away.

For many projects at once, the same change in SQL:

```sql
-- Find the flumip_user id for the person, then claim their projects.
SELECT id, email FROM flumip_user ORDER BY id;
UPDATE project SET "owner" = <user id> WHERE id IN (<project ids>);
```

## What happens when a user is deleted

Their projects become **unowned**, not deleted — the foreign key is
`ON DELETE SET NULL`. Deleting an identity must not delete the data that identity
produced. The projects fall back to being shared, and an administrator can
reassign them.

## Departments

A project can belong to a **department**, and everybody in that department can
see it. Off by default: it does nothing until an administrator names the claim
that carries group membership.

### There is no standard claim for this

OpenID Connect Core §5.1 defines twenty standard claims and **none of them
describe organisational membership**, so every provider invents its own. Set
**Settings → Sign-in → Department claim** to whichever yours uses:

| Provider | Claim |
| --- | --- |
| Okta, Auth0, Entra ID | `groups` |
| Keycloak, realm roles | `realm_access.roles` |
| Keycloak, client roles | `resource_access.flumip.roles` |
| LDAP-backed | `department` or `ou` |

Dots walk into a nested claim. The value may be a single string or an array;
both are accepted, because providers disagree about which is right. You may also
need to add a scope — `groups` at most providers — so that the claim is actually
issued.

Empty means departments are not used at all: nothing is collected and the
department clause can never match. That is the default, so an install that has
not asked for this behaves exactly as it did before the feature existed.

### What it changes

- At each sign-in the claim is read, from the ID token or from userinfo, and
  stored on the user and on their session. **Changing somebody's groups at the
  provider takes effect at their next sign-in**, the same rule the administrator
  list already follows.
- A new project is stamped with the creator's department **only when they are in
  exactly one group**. With several there is nothing to choose from, so it is
  left unset and they pick on the project tile.
- Anyone who can open a project — not just an administrator — sets its
  department, from their own groups. The server refuses a group the caller is
  not in, because otherwise this would be a way to share a project with people
  who were never meant to see it. An administrator may set any department, and
  is offered every one already in use, so that a renamed group can be tidied up.

⚠️ **A department only ever widens access.** A project with no department is
visible to its owner and to administrators, exactly as before. Switching this on
cannot take anyone's access away — but it can give access to everyone in a group,
so think about which groups your provider sends before naming the claim.

Departments are compared **verbatim, including case**: they are the provider's
own strings on both sides, and folding case would merge two groups a provider
considers distinct.

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
- **To rotate it**, clear the token; the next time anyone with access to the
  project opens UCSC a new one is minted and the old URL stops working.

  ```sql
  UPDATE project SET "trackToken" = NULL WHERE id = <project id>;
  ```

Anything you pasted into UCSC from a version before this change will have stopped
working, because those URLs used the project id. Re-open the project and use the
button again.

## Custom SNP sets

Custom SNP sets follow their own, stricter rule. Whoever adds one owns it, and
the **Share with everyone on this server** box decides who else sees it:

- **Shared** sets are visible to everybody and usable in any project, but only
  their owner and administrators can change or delete them.
- **Private** sets are visible to their owner and to administrators only.
- The SNP sets found by **Scan for new genomes** have no owner. Everybody sees
  them, and only administrators can delete them.

Unlike a project, a private set whose owner has been deleted is **not** opened up
to everyone: it stays private, and only administrators can reach it. Nothing
predates this rule, so there was no existing work to keep visible.

With sign-in off, as everywhere else, everybody can see and change everything.

## Administrators

Administrator is not a stored role — it is recomputed from the admin email list
**at sign-in**. So adding somebody to the list takes effect the next time they
sign in, not immediately, and removing somebody leaves their current session
administrative until it expires or they sign out.

### Removing someone's access immediately

There is no button to sign somebody else out. The application's own sign-out
ends only the caller's session; it drops the cached credential in the same step,
so it takes effect on the very next request.

To end everybody's sessions at once, switch **Settings → Sign-in → Require
sign-in** off and save, then on again. Switching it off ends every session,
**your own included**, and everybody signs in afresh, picking up the current
admin list and department claims as they do.

**Deleting rows in SQL does not have the same effect**, and this is worth knowing
before you rely on it in an emergency. Deleting from `auth_session` does remove
the bearer tokens — the cascade works — but the server keeps a short-lived cache
of already-issued tokens, and only its own revocation path clears it. Verified
against a running server: after `DELETE FROM auth_session`, the user's requests
still succeeded. Access ends when the cached token expires, which is **up to 30
minutes**.

So, in order of preference:

1. Have the person sign out, or switch **Require sign-in** off and on again,
   which signs everybody out.
2. If you must act out of band and cannot wait up to 30 minutes, delete their
   rows from `auth_session` and restart the service — the cache is in memory and
   does not survive it. Sessions themselves live in Postgres, so a restart does
   *not* sign everybody else out.
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
