#!/usr/bin/env python3
import boto3

ec2 = boto3.client('ec2')

response = ec2.describe_instance_status(
    Filters=[{'Name': 'event.code', 'Values': ['*']}])

statuses = {i['InstanceId']: i['Events'][0]
            for i in response['InstanceStatuses']}

response = ec2.describe_instances(InstanceIds=list(statuses.keys()))

instances = {}

for i in response['Reservations']:
    for j in i['Instances']:
        instances[j['InstanceId']] = j

for i, s in sorted(statuses.items(), key=lambda x: x[1]['NotBefore']):
    tags = {j['Key']: j['Value'] for j in instances[i]['Tags']}
    print("%9s %-19s %-20s %s" % (
        s['NotBefore'].strftime("%Y-%m-%d"),
        i,
        s['Description'],
        tags.get('Name', '')
    ))
