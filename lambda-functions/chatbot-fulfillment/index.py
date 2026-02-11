"""
Chatbot Fulfillment Lambda Function
Handles Lex V2 intent fulfillment and can invoke Bedrock (Anthropic Claude 3.5) for response generation.
"""
import json
import os
import logging
from typing import Any, Dict, Optional

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Bedrock model ID for Anthropic Claude 3.5 (override via env if needed)
BEDROCK_MODEL_ID = os.environ.get(
    "BEDROCK_MODEL_ID",
    "anthropic.claude-3-5-sonnet-20241022-v2:0",
)


def get_bedrock_response(user_message: str, intent_name: str, system_hint: Optional[str] = None) -> str:
    """
    Invoke Bedrock Anthropic Claude 3.5 model and return the generated text.
    """
    client = boto3.client("bedrock-runtime")
    system_prompt = system_hint or f"You are a helpful chatbot. The user triggered the intent: {intent_name}. Reply concisely and helpfully."
    body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 512,
        "system": system_prompt,
        "messages": [{"role": "user", "content": user_message}],
    }
    response = client.invoke_model(
        modelId=BEDROCK_MODEL_ID,
        contentType="application/json",
        accept="application/json",
        body=json.dumps(body),
    )
    result = json.loads(response["body"].read())
    # Claude Messages API response: content is a list of blocks
    text_parts = []
    for block in result.get("content", []):
        if block.get("type") == "text":
            text_parts.append(block.get("text", ""))
    return "".join(text_parts).strip() or "I'm not sure how to respond to that."


def build_lex_response(
    session_state: Dict[str, Any],
    message_content: str,
    intent_name: str,
    intent_state: str = "Fulfilled",
) -> Dict[str, Any]:
    """
    Build Lex V2 Lambda response with sessionState and messages.
    Uses dialogAction type Close to end the turn with the given message.
    """
    intent = dict(session_state.get("intent", {}))
    intent["name"] = intent_name
    intent["state"] = intent_state
    new_session = dict(session_state)
    new_session["dialogAction"] = {"type": "Close"}
    new_session["intent"] = intent
    return {
        "sessionState": new_session,
        "messages": [
            {"contentType": "PlainText", "content": message_content}
        ],
    }


def fulfill_with_bedrock(
    session_state: Dict[str, Any],
    input_transcript: str,
    intent_name: str,
    slot_values: Optional[Dict[str, str]] = None,
    use_bedrock: bool = True,
) -> Dict[str, Any]:
    """
    Fulfill the intent: optionally call Bedrock for the reply, then return Lex response.
    slot_values contains elicited slot values (e.g. UserName, HelpTopic, Feedback) for use in the reply.
    """
    slot_values = slot_values or {}
    context = f"Intent: {intent_name}. User said: {input_transcript}"
    if slot_values:
        context += f". Slot values: {json.dumps(slot_values)}"

    if use_bedrock:
        try:
            response_text = get_bedrock_response(context, intent_name)
        except Exception as e:
            logger.exception("Bedrock invoke failed: %s", e)
            response_text = f"I couldn't generate a response right now. (Error: {e})"
    else:
        # Fallback responses when Bedrock is disabled or not used (can use slot values)
        fallbacks = {
            "GreetingIntent": f"Hello{f', {slot_values.get(\"UserName\", \"\")}' if slot_values.get('UserName') else ''}! How can I help you today?",
            "HelpIntent": f"I'm here to help{f' with: {slot_values.get(\"HelpTopic\", \"\")}' if slot_values.get('HelpTopic') else ''}. You can ask me more or say what you need.",
            "GoodbyeIntent": f"Goodbye!{f' Thanks for your feedback: {slot_values.get(\"Feedback\", \"\")}' if slot_values.get('Feedback') else ''} Have a great day.",
        }
        response_text = fallbacks.get(intent_name, f"Got it. You said: {input_transcript}")

    return build_lex_response(session_state, response_text, intent_name)


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lex V2 fulfillment code hook handler.
    Expects invocationSource FulfillmentCodeHook; optionally uses Bedrock for the reply.
    """
    logger.info("Fulfillment event: %s", json.dumps(event)[:2000])

    try:
        invocation_source = event.get("invocationSource")
        if invocation_source != "FulfillmentCodeHook":
            # If used as dialog code hook, delegate back to Lex
            return {
                "sessionState": event.get("sessionState", {}),
                "messages": [],
            }

        session_state = event.get("sessionState", {})
        proposed_next = event.get("proposedNextState", {})
        intent = (session_state.get("intent") or proposed_next.get("intent") or {})
        intent_name = intent.get("name", "UnknownIntent")
        input_transcript = event.get("inputTranscript", "").strip() or "No input"
        # Slots from session (e.g. UserName, HelpTopic, Feedback) for use in fulfillment
        slots = intent.get("slots") or {}
        slot_values = {k: (v.get("value", {}) or {}).get("interpretedValue") for k, v in slots.items() if v}

        use_bedrock = os.environ.get("USE_BEDROCK_FULFILLMENT", "true").lower() == "true"

        return fulfill_with_bedrock(
            session_state=session_state,
            input_transcript=input_transcript,
            intent_name=intent_name,
            slot_values=slot_values,
            use_bedrock=use_bedrock,
        )
    except Exception as e:
        logger.exception("Fulfillment error: %s", e)
        session_state = event.get("sessionState", {})
        intent_name = (session_state.get("intent") or {}).get("name", "UnknownIntent")
        return build_lex_response(
            session_state,
            "Sorry, something went wrong. Please try again.",
            intent_name,
            intent_state="Failed",
        )
