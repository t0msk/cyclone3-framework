# c3-rlog

> Cyclone3 logs all messages to ElasticSearch. c3-rlog is a command for searching in the log stashes.

You can get the available parameters by typing:
```bash
$c3-rlog```

```txt
Cyclone3 remote log receiver
Usage: c3-rlog [options]
Basic options:
 --d=<domain>           filter to domain (default <pwd>)
 --d                    don't filter domain (disables --d,--h,--hd,--dm)
 --dm=<domain>          filter to domain master and subdomains
 --h=<hostname>         filter to hostname (default current)
 --h                    don't filter by hostname
 --hd=<hostdomain>      filter to hostdomain / Cyclone3 cluster (default current || undef)
 --t=<facility>         filter to facility (pub/pub.track/sql/...)
 --t=?                  show all available facilities by defined filter
 --f                    filter only faults
 --tail                 search, and search for new lines, and search for ...
 --msg=<string>         search in message string
 --msg=<string> --msg=...
 --filter=<elastic>     filter by custom code eg. '{"terms":{"data.test_s":["word"]}}'
 --filter=<elastic> --filter=...
 --c=<request_code>     filter to request code (disables --limit,--h,--hd)
 --p=<pid>              filter to PID
 --oldest               search for oldest lines first
 --limit=<num>          receive <num> lines of log (default 100)
 --range=<num[dhm]>     filter in date range now-<num[dhm]> ([d]ays, [h]ours, [m]inutes)
 --range                disable range filter
 --date=<YYYY-MM-DD>    filter to date
 --datetime-from=<YYYY-MM-DD HH:MM:SS> --datetime-to=<YYYY-MM-DD HH:MM:SS>
 --pretty               display additional attributes in pretty json format
 --ch                   strict chronological - don't group primary by log source
 --data.*               search terms in data.* field
 -s                     save (protect log)
```

# Tips and tricks

If you're requesting a datetime from-to range, you need to enclose the datetime values in quotation marks. Both datetime-from and datetime-to need to be specified.

`c3-rlog --datetime-from="2016-08-30 15:05:55" --datetime-to="2016-08-30 18:00:00"`

If you're searching for a string using msg, note, that two strings joined by a dot count as a single string, ie. when searching for a log message containging an email like firstname.surname@company.com :

`c3-rlog --msg=firstname # no results`

`c3-rlog --msg=surname # no results`

`c3-rlog --msg=firstname.surname # results found`

Konkrétne výstupy sa dajú ochrániť pred automatickou expiráciou ich označením pomocou prepínača -s, vhodné pre archiváciu zistených problémov

`c3-rlog --c=12345678 -s`

Aké domény nám vlastne loguje aktuálny rlog?

`c3-rlog --d=?`

Aké facilities máme zalogované?

`c3-rlog --d=domain.tld --t=?`

Hľadám výraz v ľubovolnej doméne

`c3-rlog --d --msg=vyraz`

Zrátaj koľko chýb bolo evidovaných v generovaní stránok domény za posledných 24h

`c3-rlog --d=domain.tld --t=pub.track --f --limit=0`

Zobraz všetky 404 chyby v pub.track logu

`c3-rlog --d=domain.tld --t=pub.track --data.response_status_i=404`

Čo všetko robil užívateľ posledných 24h? Zorad chronologicky

`c3-rlog --d --t=pub.track --data.user_s=gqb9mSBc --range=24h --ch`

, alebo sleduj neustale

`c3-rlog --d --t=pub.track --data.user_s=gqb9mSBc --range=24h --ch --tail`

Monitoruj mi vsetky chyby v mieste kde prave programujem

```
cd ~/Cyclone3/!domain.tld;
c3-rlog --f --ch --tail
```

Zobraz mi sql queries v pekne uhladenej forme:

`c3-rlog --d --t=sql --pretty`
