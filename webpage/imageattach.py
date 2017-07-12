#!/usr/bin/env python

# Send an email with mime image attachments.  

import argparse
import re
from datetime import datetime

from os.path import basename
from email.utils import COMMASPACE, formatdate
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.image import MIMEImage
import smtplib


def mail_images (send_from, send_to, subject, text, image_files,
                 server = '127.0.0.1'):
    """Send an email with mime images attached.
    """
    assert isinstance (send_to, list)

    msg = MIMEMultipart ()
    msg ['From'] = send_from
    msg ['To'] = COMMASPACE.join (send_to)
    msg ['Date'] = formatdate (localtime = True)
    msg ['Subject'] = subject

    msg.attach (MIMEText (text))

    for f in image_files or []:
        with open (f) as fh:
            part = MIMEImage (fh.read ())
            part.add_header ('Content-Disposition', 'attachment', filename=f)
            msg.attach (part)

    smtp = smtplib.SMTP (server)
    smtp.sendmail (send_from, send_to, msg.as_string ())
    smtp.close ()


############################################################

# Define arguments and help strings
parser = argparse.ArgumentParser (description =
                                  'Send an email with image attachments.')
parser.add_argument ('-f', '--sender',
                     help = 'from email address',
                     default = 'rkraft@cfa.harvard.edu')
parser.add_argument ('-t', '--to',
                     help = 'to addresses',
                     default = 'hrcdude@cfa.harvard.edu')
parser.add_argument ('-s', '--subject', 
                     help = 'subject')
parser.add_argument ('-x', '--text',
                     help = 'message text')
parser.add_argument ('--server',
                     help = 'mail server',
                     default = '127.0.0.1')
parser.add_argument ('image', nargs = '+',
                     help = 'image files')

# Parse arguments
argdata = parser.parse_args ()
send_from = argdata.sender
# Comma separated email address list
send_to = re.split (r'\s*,\s*', argdata.to)
subject = argdata.subject
text = argdata.text
server = argdata.server
image_files = argdata.image

# Default subject
if not subject:
    subject = datetime.now ().strftime (r'%Y:%j:%H%M%S trend plots')

mail_images (send_from, send_to, subject, text, image_files, server)
