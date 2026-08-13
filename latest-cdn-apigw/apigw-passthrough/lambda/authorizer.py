import json


def handler(event, context):
    return {
        "isAuthorized": True,
        "context": {
            "authorizerStatusCode": "200",
            "message": "Passthrough authorizer approved request",
        },
    }
