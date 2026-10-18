# AFTA IOC Domains Mirror

Unofficial daily mirror of the **AFTA (Iranian National Cybersecurity Center)** domain Indicators of Compromise (IOC) blacklist.

**Authoritative source:** [AFTA_IOC_DOMAINs.txt](https://afta.gov.ir/uploads/DOMAIN/AFTA_IOC_DOMAINs.txt)

## What this list is

These infection indicators are **contaminated / malicious domains** that organizations should place on the **blacklist of network-edge security equipment** for blocking.

AFTA publishes this domain IOC catalog daily on its website and via its channels on Bale, Eitaa, and Soroush at `@afta_iran`.

## Important warnings (from AFTA)

- **Shared hosting:** Some related IPs and hosts are shared. Besides malicious activity, they may also host legitimate services. If you depend on essential domains on those hosts, apply blocking carefully and **exclude (allowlist) necessary domains**.
- **Use only the latest list:** To keep security systems accurate, use **only the most recent** domain IOC list. Using older or locally archived copies from previous days is **not allowed** and can cause disruption or errors in related processes.

## How this repository works

| Path | Description |
|------|-------------|
| [`data/AFTA_IOC_DOMAINs.txt`](data/AFTA_IOC_DOMAINs.txt) | Latest mirrored domain list |
| [`data/metadata.json`](data/metadata.json) | Sync time, list date, domain count |
| [`.github/workflows/update-domains.yml`](.github/workflows/update-domains.yml) | Daily GitHub Action that refreshes the list |

A scheduled workflow runs every day (**06:00 UTC**) on GitHub-hosted runners, downloads the latest list, and — if the content changed — commits with a message like:

```text
Update IOC domain list (YYYY-MM-DD)
```

You can also trigger the workflow manually (**Actions → Update IOC domains → Run workflow**).

Prefer the **latest commit** in this repository over any local copy from a previous day.

## Disclaimer

This project is an **unofficial mirror** maintained for convenience and automation. **AFTA remains the authoritative source.** Always verify critical decisions against the official publication. The maintainers of this mirror are not affiliated with AFTA.

## License

Repository code and automation are under the [MIT License](LICENSE). The IOC list content originates from AFTA; retain attribution when redistributing.
