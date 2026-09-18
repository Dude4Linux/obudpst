# obudpst apk feed signing key

`obudpst-feed.pem` (private, EC prime256v1, git-ignored) and
`obudpst-feed.pub.pem` (public, tracked in git) are the signing keypair for
the obudpst OpenWrt apk feed. Generated with:

```
openssl ecparam -name prime256v1 -genkey -noout -out obudpst-feed.pem
openssl ec -in obudpst-feed.pem -pubout -out obudpst-feed.pub.pem
```

## Signing a build

Using the OpenWrt SDK's `apk` (apk-tools v3, `staging_dir/host/bin/apk`):

```
apk --allow-untrusted adbsign --sign-key obudpst-feed.pem <pkg>.apk
apk --allow-untrusted mkndx --sign-key obudpst-feed.pem -o packages.adb <pkg>.apk
```

(`--allow-untrusted` is required here only because `adbsign`/`mkndx`
verify any pre-existing signature before replacing it, and a freshly
built package has none.)

## Trusting the feed on a device

Copy the public key to the device and add the feed to apk's repository
list:

```
scp -O obudpst-feed.pub.pem qos-hq-01:/etc/apk/keys/
ssh qos-hq-01 "echo 'https://<feed-host>/path/packages.adb' >> /etc/apk/repositories.d/customfeeds.list"
```

Verified 2026-09-18: signed package + index installed on qos-hq-01
(OpenWrt 25.12.5) via `apk add` with no `--allow-untrusted` needed once
the public key was in `/etc/apk/keys/`.

## Private key custody

`obudpst-feed.pem` is git-ignored and exists only on this workstation
(`packaging/openwrt/keys/`). Back it up somewhere durable (password
manager / offline storage) before relying on it for real releases —
losing it means re-signing means re-trusting a new key on every device.
