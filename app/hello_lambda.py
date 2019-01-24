import os
import json


def lambda_handler(event, context):
    greeting = os.getenv("greeting", "Hi")
    message = {"message": "%s from Lambda!" % greeting}

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json; charset=utf-8"},
        "body": json.dumps(message),
    }
