# Lastpass enterprise provisioning tool

A simple tool to let you provision lastpass users from a CSV file.

1. Set up your credentials - go to
<https://lastpass.com/enterprise_create.php?api=1> to get the values of cid
and provhash, and create a credentials.json file:

        {
          "cid": "...",
          "provhash": "..."
        }

1. Put your users in a `users.csv` file. The file should have a header line
with 3 columns - email, name and groups:

        email,name,groups
        foo@example.com,Foo Barrington,Group1;Group2
        bar@example.com,Barry Baz,Group1;Group3

1. Run the lastpass provisioning tool. It will create the users, and output
the users and their temporary passwords in csv format. Redirect the output to
a file to save them.
