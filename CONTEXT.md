# Konteyner

The shared foundation that new mobile, tablet and web apps are started from.

## Language

**Konteyner**:
The template itself: the common foundation every new app starts from, configured with minimal setup.
_Avoid_: base app, starter, boilerplate

**Public Konteyner**:
This repository. Generic and public; holds no company-specific rules.

**Company copy**:
A private duplicate of the Public Konteyner that keeps merging updates from it and adds the company layer.
_Avoid_: fork, mirror

**Derived app**:
A real app started from a Konteyner, living in its own private repository.
_Avoid_: client app, child project

**Company layer**:
Rules that belong to one company (commit conventions, tracker conventions, internal links). Never present in the Public Konteyner.

**First-class platform**:
A platform where every Konteyner feature works and is built and tested in CI: Android, iOS, web.

**Build-only platform**:
A platform that is built in CI but where features needing a missing native SDK switch themselves off: macOS, Windows, Linux.
_Avoid_: unsupported platform, secondary platform

**Minimum OS**:
The oldest OS version a platform supports. Konteyner always matches Flutter's own minimum; a Derived app may raise it, never lower it.

**Flavor**:
One of an app's three build variants (dev, staging, prod), each with its own backend, identifiers and Firebase project.
_Avoid_: environment, env

**Feature**:
A product capability the app's users see, such as login or orders. Belongs to one app.
_Avoid_: module, screen

**Module**:
An optional piece of infrastructure that a Derived app opts into, such as Firebase, Sentry or push.
_Avoid_: feature, plugin, kit

**Core**:
The infrastructure every app always gets, such as configuration, networking, routing, theme, localization and logging.
_Avoid_: base, common

**Session**:
A user's signed-in state on one device. It begins at login and ends at logout or when it can no longer be renewed.
_Avoid_: login, auth state

**Remember me**:
The user's choice to have the login form pre-filled on this device. It does not decide whether the user stays signed in; the Session always survives a restart.
_Avoid_: stay signed in, keep me logged in

**Permission area**:
A part of the app the backend grants a user by including it in their permissions; a missing area means no access. Decided by the backend, so it need not match a **Feature** one to one.
_Avoid_: module, sub-module, role, permission (that word is kept for device permissions such as camera or notifications)

**Component rule**:
A backend override for one control inside a granted **Permission area**: hidden, readonly or disabled. A control without a rule is unrestricted.
_Avoid_: action, button permission

**Minimum app version**:
The oldest app version the user may keep using; below it the app is blocked until the user updates.
_Avoid_: force update version, mandatory version

**Recommended app version**:
The version users are encouraged to update to; below it the user is prompted but may dismiss the prompt.
_Avoid_: optional update, soft version

**Log**:
A line for developers describing what the app did; each **Flavor** keeps or drops it by level.
_Avoid_: trace, print

**Breadcrumb**:
A short note of a recent event, attached to the next **Error report** so the lead-up is visible.
_Avoid_: trail, event

**Error report**:
An error sent to the error tracker; fatal when the app could not continue.
_Avoid_: crash (only for fatal ones), event, issue

## Relationships

- The **Public Konteyner** feeds one or more **Company copies**; changes flow one way, public to company
- A **Company copy** adds the **Company layer** without editing files the **Public Konteyner** owns
- A **Derived app** is started from a **Company copy** and inherits its **Company layer**
- A **Derived app** is created once and never merges later updates from its **Company copy**
- A **Derived app** starts with every **Module** and removes the ones it doesn't use; **Core** always stays
