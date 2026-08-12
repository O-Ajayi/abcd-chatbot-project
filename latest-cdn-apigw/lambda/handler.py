import json


def handler(event, context):
    query_params = event.get("queryStringParameters") or {}
    if not isinstance(query_params, dict):
        query_params = {}

    user_input = query_params.get("input") or ""

    message = "hub-central-ui is up and running"
    if user_input:
        message = f"{message} - received input: {user_input}"

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(
            {
                "status": "ok",
                "message": message,
                "input": user_input,
            }
        ),
    }
