#!/usr/bin/env python3

import os
import smtplib
import requests
from datetime import datetime

package_url = "http://store.data.threesixtygiving.org/grantnav_packages/latest_grantnav_data.tar.gz"


def send_alert(text):
    to = os.environ.get("TO", "servers@opendataservices.coop")
    from_ = os.environ.get("FROM", "servers@opendataservices.coop")

    header = "To:%s\nFrom:%s\nSubject:WARNING: 360G Datastore Data Package issue\n" % (to, from_)

    content = header + "\n\n" + text

    mail = smtplib.SMTP(
        os.environ.get("SMTP_HOST", "smtp-relay.gmail.com"),
        os.environ.get("SMTP_PORT", 587),
    )

    mail.ehlo()
    mail.starttls()

    mail.sendmail(from_, to, content)
    mail.quit()


# Script Checks the 360 datastore to see if a data package has been generated today
def main():
    try:
        r = requests.head(
            package_url, auth=(os.environ.get("USER"), os.environ.get("PASSWORD"))
        )
        r.raise_for_status()

        pkg_modified = datetime.strptime(
            r.headers["Last-Modified"], "%a, %d %b %Y %H:%M:%S %Z"
        )

        today = datetime.now()

        str_pkg_mod = pkg_modified.strftime("%Y-%m-%d")
        str_today = today.strftime("%Y-%m-%d")

        if str_today != str_pkg_mod:
            send_alert(
                "There is no latest_grantnav_data package available for today (%s). Latest available is %s"
                % (str_today, str_pkg_mod)
            )

    except Exception as e:
        send_alert(
            "Error checking the datastore for the latest data package at %s"
            % package_url
        )
        print(e)


if __name__ == "__main__":
    main()
