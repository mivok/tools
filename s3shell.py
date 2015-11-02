#!/usr/bin/env python
# Copyright (c) 2015 Mark Harrison
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
"""
S3 interactive shell

This is a simple wrapper around the aws command line tools that will let you
interact with files in s3 like you would with a shell, using ls/cd and so on.
"""
import argparse
import cmd
import inspect
import os
import shlex
import sys
import tempfile

class s3shell(cmd.Cmd):

    def __init__(self, args):
        self.bucket = args.bucket
        self.profile = args.profile
        self.cwd = '/'
        self.debug = args.debug
        self.update_prompt()
        cmd.Cmd.__init__(self)

    def emptyline(self):
        # Don't do anything when a blank command is entered.
        pass

    def update_prompt(self):
        self.prompt = "%s%s> " % (self.bucket, self.cwd)

    def aws_s3(self, cmd):
        if self.bucket == '':
            print "No bucket selected"
            return
        full_cmd = "aws --profile %s s3 %s" % (self.profile, cmd)
        if self.debug:
            print full_cmd
        os.system(full_cmd)

    def baseurl(self):
        return "s3://%s%s" % (self.bucket, self.cwd)

    def full_path(self, filename):
        if filename.startswith("s3://") or filename.startswith("/"):
            return filename
        else:
            return "%s%s" % (self.baseurl(), filename)

    def download_temp(self, filename):
        local_file = tempfile.mkstemp()
        self.aws_s3("cp %s %s" % (self.full_path(filename), local_file[1]))
        return local_file[1]

    def do_debug(self, line):
        """Toggle debug mode"""
        self.debug = not self.debug
        print "Debug mode: %s" % (self.debug and "On" or "Off")

    def do_profile(self, line):
        """Show/changes the current AWS profile

        Usage: profile [PROFILENAME]

        If profile is left out, this command will just show the current
        profile, otherwise it will change the profile in use.
        """
        if line != '':
            self.profile = line
        print "Profile set to: %s" % line

    def do_bucket(self, line):
        """Change the current bucket name

        Usage: bucket BUCKETNAME
        """
        if line:
            self.bucket = line
            self.update_prompt()
        else:
            print "Error: Missing bucket name"
            self.do_help('bucket')

    def do_ls(self, line):
        """List the contents of the current directory in S3.

        Usage: ls
        """
        if not line:
            self.aws_s3("ls %s" % self.baseurl())
        else:
            parts = shlex.split(line)
            filename = parts[0]
            self.aws_s3("ls %s" % self.full_path(filename))

    def do_cd(self, line):
        """Change the current (remote) directory.

        Usage: cd DIRECTORY

        If a directory is not given, then change to the root of the current
        bucket.
        """
        if line == '':
            self.cwd = '/'
        elif line.startswith('/'):
            self.cwd = line
        else:
            parts = line.split('/')
            cwd = self.cwd[1:].split('/')
            if cwd == ['']:
                cwd = []
            for part in parts:
                if part == '.':
                    pass
                elif part == '..':
                    if cwd:
                        cwd.pop()
                else:
                    cwd.append(part)
            self.cwd = '/%s' % '/'.join(cwd)
            if not self.cwd.endswith('/'):
                self.cwd = '%s/' % self.cwd
        self.update_prompt()

    def do_cat(self, line):
        """Display the contents of a file stored in S3

        Usage: cat FILENAME
        """
        if not line:
            print "Error: Missing filename"
            self.do_help('cat')
            return
        parts = shlex.split(line)
        filename = parts[0]
        local_file = self.download_temp(filename)
        with open(local_file) as fh:
            print fh.read()
        os.remove(local_file)

    def do_less(self, line):
        """Display the contents of a file stored in S3 with less

        Usage: less FILENAME
        """
        if not line:
            print "Error: Missing filename"
            self.do_help('less')
            return
        parts = shlex.split(line)
        filename = parts[0]
        local_file = self.download_temp(filename)
        os.system('less "%s"' % local_file)
        os.remove(local_file)

    def do_cp(self, line):
        """Copy files (remotely)

        Usage: cp FILENAME1 FILENAME2
        """
        parts = shlex.split(line)
        if len(parts) < 2:
            print "Error: Missing filename"
            self.do_help('cp')
            return
        self.aws_s3("cp %s" % ' '.join([
            "'%s'" % self.full_path(p) for p in parts]))

    def do_mv(self, line):
        """Move/rename files (remotely)

        Usage: cp FILENAME1 FILENAME2
        """
        parts = shlex.split(line)
        if len(parts) < 2:
            print "Error: Missing filename"
            self.do_help('mv')
            return
        self.aws_s3("mv %s" % ' '.join([
            "'%s'" % self.full_path(p) for p in parts]))

    def do_rm(self, line):
        """Delete a file from S3

        Usage: rm FILENAME
        """
        if not line:
            print "Error: Missing filename"
            self.do_help('rm')
            return
        parts = shlex.split(line)
        filename = parts[0]
        self.aws_s3("rm '%s'" % self.full_path(filename))

    def do_get(self, line):
        """Download a file from S3

        Usage: get FILENAME
        """
        if not line:
            print "Error: Missing filename"
            self.do_help('get')
            return
        parts = shlex.split(line)
        filename = parts[0]
        self.aws_s3("cp '%s' ." % (self.full_path(filename)))

    def do_put(self, line):
        """Upload a file to S3

        Usage: put FILENAME
        """
        if not line:
            print "Error: Missing filename"
            self.do_help('put')
            return
        parts = shlex.split(line)
        filename = parts[0]
        self.aws_s3("cp '%s' '%s'" % (filename, self.baseurl()))

    def do_edit(self, line):
        """Edit a file locally using a text editor.

        Usage: edit FILENAME

        This uses the $EDITOR environment variable to determine the editor to
        use, or defaults to 'vi' if the editor isn't set.
        """
        if not line:
            print "Error: Missing filename"
            self.do_help('edit')
            return
        parts = shlex.split(line)
        filename = parts[0]
        local_file = self.download_temp(filename)
        previous_modtime = os.stat(local_file).st_mtime
        editor = 'vi'
        if 'EDITOR' in os.environ and os.environ['EDITOR'] != '':
            editor = os.environ['EDITOR']
        os.system('"%s" "%s"' % (editor, local_file))
        if os.stat(local_file).st_mtime != previous_modtime:
            # File was modified, let's upload it
            self.aws_s3("cp '%s' '%s'" % (local_file, self.full_path(filename)))
        else:
            print "File wasn't modified. Not uploading."
        os.remove(local_file)

    def do_EOF(self, line):
        """Exit the program with ^D"""
        print
        sys.exit(0)

    def do_exit(self, line):
        """Exit the program"""
        sys.exit(0)

    def do_help(self, arg):
        'List available commands with "help" or detailed help with "help cmd".'
        # This is a custom help function that does a better job with docstring
        # help functions.
        if arg:
            try:
                doc = getattr(self, 'do_' + arg).__doc__
                if doc:
                    print "Help for %s:" % arg
                    print inspect.cleandoc(doc)
                    print
                else:
                    print self.nohelp % arg
            except AttributeError:
                print self.nohelp % arg
        else:
            # Default behavior for a help command without args
            cmd.Cmd.do_help(self, arg)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='S3 interactive shell')
    parser.add_argument('--profile', default='default')
    parser.add_argument('--debug', action='store_true')
    parser.add_argument('--bucket', default='')
    args = parser.parse_args()
    c = s3shell(args)
    c.cmdloop("S3 Shell\nProfile: %s" % args.profile)
