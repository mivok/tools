#!/usr/bin/env python3
# Tool to restore files from glacier in an entire s3 bucket. For use when
# glacier turned out not to be the right option after all.

# Usage:
# First, initiate a restore using --restore. This will take several hours.
# Check on the status using --status. Once all files are restored, you then
# change the storage class to standard with --fixclass so that the files don't
# get deleted after 30 days.

import argparse

import boto3


class GlacierTool(object):
    def __init__(self):
        self.s3 = boto3.client('s3')

    def parse_args(self):
        parser = argparse.ArgumentParser(
            description='Manage files in glacier')
        action = parser.add_mutually_exclusive_group(required=True)
        action.add_argument('--restore', '-r', action='store_true',
                            help='Initiate a restore from glacier')
        action.add_argument('--status', '-s', action='store_true',
                            help='Check on the status of a restore')
        action.add_argument('--fixclass', '-f', action='store_true',
                            help='Convert restored objects to standard '
                            'storage class')
        parser.add_argument('--bucket', '-b', required=True,
                            help='The S3 bucket to use')
        self.args = parser.parse_args()

    def get_glacier_objects(self):
        objects = self.s3.list_objects_v2(Bucket=self.args.bucket)
        keys = [i['Key'] for i in objects['Contents']
                if i['StorageClass'] == 'GLACIER']
        return keys

    def initiate_restore(self, key):
        self.s3.restore_object(Bucket=self.args.bucket, Key=key,
                               RestoreRequest={"Days": 30})

    def get_restore_status(self, key):
        rv = self.s3.head_object(Bucket=self.args.bucket, Key=key)
        return 'Restore' in rv and rv['Restore'] == 'ongoing-request="true"'

    def convert_to_standard_storage_class(self, key):
        self.s3.copy_object(Bucket=self.args.bucket, Key=key,
                            CopySource={"Bucket": self.args.bucket,
                                        "Key": key},
                            StorageClass='STANDARD')

    def run(self):
        if self.args.restore:
            for o in self.get_glacier_objects():
                self.initiate_restore(o)
                print(o, 'Restore initiated')
        elif self.args.status:
            for o in self.get_glacier_objects():
                status = self.get_restore_status(o) and 'Restoring' or 'Done'
                print(o, status)
        elif self.args.fixclass:
            for o in self.get_glacier_objects():
                if self.get_restore_status(o):
                    print(o, 'Still restoring')
                else:
                    self.convert_to_standard_storage_class(o)
                    print(o, 'Converted to standard storage class')


if __name__ == '__main__':
    gt = GlacierTool()
    gt.parse_args()
    gt.run()
