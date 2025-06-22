import json
import boto3
import bcrypt
import jwt
import os
from botocore.exceptions import ClientError

dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')

USERS_TABLE = os.environ['USERS_TABLE']
BUCKET_NAME = os.environ['BUCKET_NAME']
JWT_SECRET = os.environ['JWT_SECRET']

def lambda_handler(event, context):
    path = event.get('rawPath')
    method = event.get('requestContext', {}).get('http', {}).get('method')

    if path == '/register' and method == 'POST':
        return register(event)
    elif path == '/login' and method == 'POST':
        return login(event)
    elif path == '/list-files' and method == 'GET':
        return list_files(event)
    elif path == '/get-upload-url' and method == 'POST':
        return get_upload_url(event)
    else:
        return response(404, {'message': 'Not found'})

def register(event):
    body = json.loads(event['body'])
    username = body.get('username')
    password = body.get('password')

    if not username or not password:
        return response(400, {'message': 'Username and password required'})

    table = dynamodb.Table(USERS_TABLE)
    hashed_pw = bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

    try:
        table.put_item(
            Item={'username': username, 'passwordHash': hashed_pw},
            ConditionExpression='attribute_not_exists(username)'
        )
        return response(201, {'message': 'User registered'})
    except ClientError:
        return response(400, {'message': 'User already exists'})

def login(event):
    body = json.loads(event['body'])
    username = body.get('username')
    password = body.get('password')

    table = dynamodb.Table(USERS_TABLE)
    user = table.get_item(Key={'username': username}).get('Item')

    if not user or not bcrypt.checkpw(password.encode(), user['passwordHash'].encode()):
        return response(401, {'message': 'Invalid credentials'})

    token = jwt.encode({'username': username}, JWT_SECRET, algorithm='HS256')
    return response(200, {'token': token})

def list_files(event):
    username = verify_token(event)
    if not username:
        return response(401, {'message': 'Unauthorized'})

    prefix = f'users/{username}/'
    try:
        s3_response = s3.list_objects_v2(Bucket=BUCKET_NAME, Prefix=prefix)
        contents = s3_response.get('Contents', [])

        files = [ {
            'name': obj['Key'].split('/')[-1],
            'url': s3.generate_presigned_url(
                'get_object',
                Params={'Bucket': BUCKET_NAME, 'Key': obj['Key']},
                ExpiresIn=3600
            )
        } for obj in contents ]

        return response(200, files)
    except Exception:
        return response(500, {'message': 'Failed to list files'})

def get_upload_url(event):
    username = verify_token(event)
    if not username:
        return response(401, {'message': 'Unauthorized'})

    try:
        body = json.loads(event.get("body", "{}"))
        filename = body.get("filename")
        if not filename:
            return response(400, {"message": "Filename is required"})

        object_key = f"users/{username}/{filename}"
        signed_url = s3.generate_presigned_url(
            ClientMethod='put_object',
            Params={'Bucket': BUCKET_NAME, 'Key': object_key},
            ExpiresIn=3600
        )

        return response(200, {"url": signed_url, "key": object_key})
    except Exception:
        return response(500, {'message': 'Could not generate upload URL'})

def verify_token(event):
    auth_header = event['headers'].get('Authorization', '')
    if not auth_header.startswith('Bearer '):
        return None
    token = auth_header.replace('Bearer ', '')
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
        return payload.get('username')
    except Exception:
        return None

def response(status, body):
    return {
        'statusCode': status,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': '*'
        },
        'body': json.dumps(body)
    }