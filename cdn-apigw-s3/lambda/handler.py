import json


def handler(event, context):
    query_params = event.get("queryStringParameters") or {}
    user_input = query_params.get("input", "")

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
