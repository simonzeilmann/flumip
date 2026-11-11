# Running a public instance

FLUMIP was built as an internal service, but it can also run as a public website
that anyone can use without an account, the way UCSC's BLAT is. This document
covers what **public mode** changes and how to set up a server for it.

**Run a public instance on its own server, with its own database.** Don't switch
an internal install to public mode. Public mode changes who can see existing
projects (see "Unowned projects" below), and internal work should never share a
database with the internet.

## What visitors see

1. **The entry notice.** A first visit gets a full-screen notice in place of the
   app. It says what the site's one cookie is for, states the terms of use
   (non-commercial, academic research use only, unless you write your own) and
   links your imprint and privacy policy. **Accept and continue** is the only way
   in. **Decline** leaves the notice up and explains that FLUMIP can't be used
   without accepting.
2. **Their own projects, and only those.** Accepting makes the visitor a
   *guest*: an anonymous identity held in a cookie. Guests see only the projects
   they created and the ones opened from a share link. Nobody sees anybody
   else's.
3. **A deletion date on every project.** A guest's projects are deleted
   automatically, and each one shows the last day it is kept. **Keep longer** adds another
   retention window to that date each time it is pressed, up to a maximum you
   set.
4. **A share link on every project.** **Copy link** gives an address like
   `https://mips.example.org/#/p/<token>`. Opening it adds the project to that
   browser's list. That is how a guest gets back to a project from another
   browser or computer, and how they share it with a colleague.

   A browser that has not been here before shows the entry notice first, even
   when it arrives by a share link. That is expected: the notice is accepted
   per browser, because the cookie it sets is what that browser is known by.
   Accepting it there loses nothing. The new browser becomes a guest of its
   own, the shared project is added to its list, and the first browser keeps
   everything it had.

Guests can browse the genome library and use every SNP set you provide.

They can also **upload small SNP sets of their own**: a `.vcf.gz` and
optionally its `.tbi`, each up to 10 MB by default. A guest's set is visible
only to them and to administrators, can't be shared, and is deleted
automatically after 7 days. A project that used it then runs without SNP
masking. Each guest may have 3 sets at a time. All three numbers are settings
(see below), and a size limit of 0 turns guest uploads off.

Guests **cannot**:

- import SNP sets from a URL, or rescan the SNP tree (a URL import has the
  server fetch whatever address it is given)
- scan for genomes, build or delete indexes, or switch genomes on and off
- open Settings
- turn on email notifications (guests have no address)

## Signed-in users

Anyone who signs in through single sign-on is a *signed-in user*, not a guest,
whether they are an administrator or not. Signed-in users work as they would on
an internal install:

- Their projects are **never deleted automatically** and show no deletion date
  (see "Expiry" below).
- They can add, upload and import SNP sets.
- They can add to the genome library: scan for genomes you have put on the
  server, and build a genome's index. They cannot take from it. **Deleting an
  index and switching a genome on or off are for administrators only.**
- They don't count against **Projects per visitor**, and can turn on email
  notifications.

Only administrators can open Settings, delete a genome's index, or switch a
genome on or off.

This makes who can sign in matter more than on an internal install. Everybody
your identity provider lets in gets storage with no time limit, so keep
**Allowed email domains** narrow, or let the identity provider decide. With
Pocket ID, only the people you add to the client's group can sign in: add them
the way [pocket-id.md](pocket-id.md#administration) describes for an
administrator, but leave their address off the administrator list.

## Switching it on

Public mode needs single sign-on, because that is how administrators get in once
it is on. **A public instance does not accept the settings password**: from the
moment public mode is saved, the password stops opening Settings. On a server
anyone can reach, a shared password is a brute-force target.

No identity provider of your own to sign in with? Both installers can host one
next to FLUMIP: see [pocket-id.md](pocket-id.md).

So the order matters:

1. Configure single sign-on as described in [authentication.md](authentication.md),
   with your own address on the administrator list.
2. Switch **Require sign-in** on and save. Sign in with your administrator
   address.
3. Open **Settings → Public instance**, switch **Public mode** on, fill in the
   fields below, and save.
4. Optionally switch **Require sign-in** off again. Public mode keeps sign-in
   available for administrators either way: the **Administrator sign-in** link
   is on the entry notice and in the app bar.

Step 3 is refused unless you are signed in as an administrator. That check is
deliberate: being signed in proves the way back into Settings works before you
need it.

You can also set `FLUMIP_PUBLIC_MODE=true` in the environment
(`/etc/flumip/flumip.env`, or `.env` beside `compose.yaml` with Docker). It
overrides the stored setting in both directions, and the Settings tab then shows
the switch read-only.

### If you are locked out

`FLUMIP_PUBLIC_MODE=false` plus a restart turns public mode off, and the settings
password works again. Do the same if single sign-on breaks on a public
instance: the server logs `Public mode is on but single sign-on is not fully
configured` every 30 seconds when nobody can sign in.

Switching public mode off ends every guest session. Guests' projects stay until
they expire.

## Settings

All in **Settings → Public instance**, except the first.

| Setting | Default | What it does |
| --- | --- | --- |
| Keep projects for (hours), under **Security** | 48 | How long a guest's new project lives, rounded up to the end of that day. Public mode implies demo-mode deletion, and this is its window. It is also what each **Keep longer** adds. |
| Longest a project can be kept (days) | 14 | How far **Keep longer** can push a deletion, counted from creation. Never shorter than the window above. Also how long a guest's cookie lasts between visits. |
| Projects per visitor | 10 | How many projects one guest may have at a time. 0 means no limit. Administrators and signed-in users are not counted. |
| Largest SNP file a visitor can upload (MB) | 10 | Applies to the VCF and the index separately. 0 means guests cannot add SNP sets. |
| SNP sets per visitor | 3 | How many SNP sets one guest may have at a time, failed uploads included. 0 means no limit. |
| Keep a visitor's SNP set for (days) | 7 | Counted from the upload, rounded up to the end of that day. There is no **Keep longer** for SNP sets. |
| Terms of use on the entry notice | empty | Replaces the default terms paragraph. The cookie paragraph is always shown. |
| Terms version | 1 | Raise it after changing the terms. Every guest sees the notice again on their next visit and keeps their projects once they accept. |
| Imprint (Impressum) URL | empty | Linked from the entry notice and the footer. |
| Privacy policy URL | empty | Linked from the entry notice and the footer. |

And in **Settings → Run limits**, which apply to every install:

| Setting | Default | What it does |
| --- | --- | --- |
| Designs running at once | 0 (no limit) | Any more wait in a queue and start by themselves, oldest first. **Set this on a public instance.** Start with the number of CPU cores divided by the bwa threads per design. |
| Most bwa threads per design | 0 (no limit) | Caps what a project's options can ask for. |

On a public instance each guest may also have only **one** design running or
waiting at a time, so one visitor cannot fill the queue ahead of everybody else.

## Expiry

Only guests' projects expire. Whether a project does is decided when it is
created: a guest's gets a deletion date, a signed-in user's doesn't and is kept
until somebody deletes it. A guest's project keeps its date after the guest's
identity is cleaned up. **Demo mode changes nothing on a public instance.**

An administrator who changes a project's **Owner** changes this too. Handing a
guest's project to a signed-in user keeps it. Handing a project to a guest gives
it a fresh window from today. Setting it to unowned leaves it as it was.

Projects are kept in whole days. A project created on 28 October with a 7-day
window shows "kept until 4 November" and is deleted when that day ends, at
midnight in the **server's** time zone. Each press of **Keep longer** adds
another window to that date, but never past the day on which creation plus the
maximum lifetime falls. Once it reaches that day the button is disabled.

The app shows the date in the visitor's time zone. For visitors in the server's
time zone, which is the case FLUMIP is built for, the two always agree. Far east
of the server, the last day can look one day later than the server means it.

The deletion runs when the day ends, whether or not anyone is looking.

### Keeping a project indefinitely

An administrator can exempt any guest's project from deletion, for example one
cited in a paper. Sign in, open the project and select **Keep indefinitely**. The project
then shows "Kept indefinitely by an administrator" instead of a date, and
**Keep longer** disappears. Owners cannot do this themselves. They can only keep
a project longer, up to the maximum.

Clearing **Keep indefinitely** puts the project back under the normal rule with
a **fresh** window counted from today, so a project whose old date has long
passed is not deleted the moment the flag comes off.

The retention window and the maximum lifetime are global settings (see the table
below). They can't be set per project; **Keep indefinitely** is the one
per-project exception. It
removes the project, its options and its whole directory, exactly like the
delete button.

Raising the retention window later spares projects that are already scheduled.
Lowering it affects new projects only. Nothing is deleted earlier than the date
it was given.

## Share links

Anyone who has a project's link can open the project and change it, **including
deleting it**. A link is not read-only. This matches the rest of FLUMIP: whoever
can see a project can change it.

The token is 32 random bytes and sits in the URL's fragment (after `#`). Browsers
never send the fragment to the server, so the token stays out of access logs and
proxies. The app reads it, opens the project once the visitor has accepted the
notice, then removes it from the address bar.

**Reset link** on the project withdraws it. The old link stops working **and**
everybody who opened it loses access, including the owner's own other browsers.
The new link can then be shared again.

## Unowned projects

On an internal install, a project without an owner is visible to everyone; that
keeps old projects reachable after single sign-on is switched on. **On a public
instance, unowned projects are visible to administrators only.** There, a project
loses its owner when the guest's cookie expires and the identity is cleaned up,
and it must not then show up for every visitor. People who opened it from a share
link keep it.

The **Owner** menu on a project says so: its first entry reads **Unowned —
administrators only** here, and **Unowned — shared with everyone** on an internal
install. Guests are not offered as owners; a guest appears in the menu only on a
project they currently own, as **Guest #** and a number.

This is the main reason not to switch an existing internal install to public
mode: all its unowned projects would disappear from everyone but administrators.

## Rate limiting

FLUMIP limits runs, projects per guest and uploads, but not the rate of requests.
Do that at the reverse proxy. With nginx:

```nginx
# In the http block.
limit_req_zone $binary_remote_addr zone=flumip_auth:10m rate=10r/m;
limit_req_zone $binary_remote_addr zone=flumip_api:10m  rate=20r/s;

# In the server block, beside the existing proxy_pass location.
location = /auth/guest {
    limit_req zone=flumip_auth burst=5 nodelay;
    proxy_pass http://127.0.0.1:9082;
}
location /api/ {
    limit_req zone=flumip_api burst=40 nodelay;
    proxy_pass http://127.0.0.1:9082;
}
```

`/auth/guest` is the entry notice's **Accept** button, and the only thing that
creates a guest, so it is the one to keep tight. The app polls the API every few
seconds while a design runs, so leave the API zone generous.

## Cookies, privacy and the law

This section is not legal advice. It describes what the software does, so whoever
writes your privacy policy can describe it correctly.

- **One cookie**, `flumip_auth`: HttpOnly, `SameSite=Lax`, `Secure` behind HTTPS,
  set only when the notice is accepted. It identifies the browser's guest session.
  Only its SHA-256 hash is stored on the server. It lasts as long as the longest
  project lifetime and is renewed on each visit.
- **What is stored about a guest:** a random identifier, when they accepted the
  notice and which terms version, when their identity was created and last used,
  their projects, and any SNP sets they uploaded. No name, no email address, no IP address in the database.
  (Your reverse proxy's access log is a separate matter.)
- **Deletion:** a guest's projects and SNP sets are deleted when their last day ends.
  Their identity is deleted once their cookie has expired.
- **Consent:** a cookie that is strictly necessary for a service the visitor asked
  for needs no consent under § 25(2) TDDDG (formerly TTDSG) and Art. 5(3) of the
  ePrivacy Directive. The notice informs visitors about it. What it actually asks
  them to accept is the terms of use.
- **Third parties:** check that the web build loads nothing from outside your
  server. Flutter's default web build fetches its rendering engine and fonts from
  Google's CDN. FLUMIP's builds pass `--no-web-resources-cdn` and bundle their
  fonts so that it does not. If you build the app yourself, keep that flag, or
  the cookie notice's "no third-party services" stops being true.

⚠️ **MIPGEN's licence.** MIPGEN is licensed by the University of Washington for
non-commercial academic and research use only, which is why the default terms say
the same. That licence does not mention offering MIPGEN as a public web service.
Confirm with license@uw.edu before you announce a public instance.
