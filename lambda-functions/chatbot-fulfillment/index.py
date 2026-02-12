"""
Chatbot Fulfillment Lambda Function
Handles Lex V2 intent fulfillment and general conversation. All user input is sent to Bedrock:
- Satisfies Lex intents (Greeting, Help, Goodbye, Fallback) with natural responses.
- Handles any other question or conversation turn with full context (optional history).
Uses BEDROCK_INFERENCE_PROFILE_ARN (recommended) or BEDROCK_MODEL_ID as the modelId for InvokeModel.
"""
import json
import os
import logging
from typing import Any, Dict, List, Optional, Tuple

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Session attribute key for conversation history (list of {"role":"user"|"assistant","content":"..."})
# Set CONVERSATION_HISTORY_TURNS=0 to disable history; default 10.
HISTORY_KEY = "chatHistory"
MAX_HISTORY_TURNS = int(os.environ.get("CONVERSATION_HISTORY_TURNS", "10"))


def _get_bedrock_model_id() -> str:
    """
    Resolve the Bedrock model identifier for InvokeModel.
    Prefer BEDROCK_INFERENCE_PROFILE_ARN (inference profile ID or ARN); fallback to BEDROCK_MODEL_ID.
    In many accounts/regions, InvokeModel requires an inference profile that contains the model.
    """
    profile = os.environ.get("BEDROCK_INFERENCE_PROFILE_ARN", "").strip()
    if profile:
        return profile
    return os.environ.get(
        "BEDROCK_MODEL_ID",
        "anthropic.claude-3-5-sonnet-20241022-v2:0",
    )


def _parse_history(session_attributes: Dict[str, str]) -> List[Dict[str, str]]:
    """Load conversation history from session attributes (last N turns)."""
    if MAX_HISTORY_TURNS <= 0:
        return []
    raw = (session_attributes or {}).get(HISTORY_KEY)
    if not raw:
        return []
    try:
        history = json.loads(raw)
        if isinstance(history, list):
            return history[-MAX_HISTORY_TURNS * 2 :]  # user+assistant pairs
        return []
    except (json.JSONDecodeError, TypeError):
        return []


def _save_history(
    session_attributes: Dict[str, str],
    user_message: str,
    assistant_message: str,
) -> Dict[str, str]:
    """Append this turn to history and return updated session attributes."""
    if MAX_HISTORY_TURNS <= 0:
        return dict(session_attributes or {})
    history = _parse_history(session_attributes or {})
    history.append({"role": "user", "content": user_message})
    history.append({"role": "assistant", "content": assistant_message})
    kept = history[-(MAX_HISTORY_TURNS * 2) :]
    out = dict(session_attributes or {})
    out[HISTORY_KEY] = json.dumps(kept)
    return out


def get_bedrock_response(
    user_message: str,
    intent_name: str,
    system_hint: Optional[str] = None,
    message_history: Optional[List[Dict[str, str]]] = None,
) -> str:
    """
    Invoke Bedrock: handles both Lex intent fulfillment and general conversation.
    Uses optional message_history for multi-turn context.
    """
    client = boto3.client("bedrock-runtime")
    model_id = _get_bedrock_model_id()
    system_prompt = (
        system_hint
        or "You are a helpful, friendly assistant in a Lex chatbot. "
        "You both fulfill Lex intents (e.g. greeting, help, goodbye) and answer general questions. "
        "Reply in a natural, concise way. For greetings be warm; for help offer assistance; for goodbye be brief. "
        "For any other question or comment, answer helpfully. Keep responses appropriate for voice or text."
    )
    messages: List[Dict[str, str]] = []
    if message_history:
        messages.extend(message_history)
    messages.append({"role": "user", "content": user_message})
    body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 1024,
        "system": system_prompt,
        "messages": messages,
    }
    response = client.invoke_model(
        modelId=model_id,
        contentType="application/json",
        accept="application/json",
        body=json.dumps(body),
    )
    result = json.loads(response["body"].read())
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
    session_attributes_override: Optional[Dict[str, str]] = None,
) -> Dict[str, Any]:
    """
    Build Lex V2 Lambda response with sessionState and messages.
    Uses dialogAction type Close so Lex ends the turn and shows our message.
    Optionally updates sessionAttributes (e.g. conversation history).
    """
    new_session = dict(session_state)
    if session_attributes_override is not None:
        new_session["sessionAttributes"] = session_attributes_override
    intent = dict(new_session.get("intent", {}))
    intent["name"] = intent_name
    intent["state"] = intent_state
    if "confirmationState" not in intent:
        intent["confirmationState"] = "None"
    intent.setdefault("slots", {})
    new_session["dialogAction"] = {"type": "Close"}
    new_session["intent"] = intent
    text = (message_content or "How can I help you?").strip() or "How can I help you?"
    return {
        "sessionState": new_session,
        "messages": [
            {"contentType": "PlainText", "content": text}
        ],
    }


def fulfill_with_bedrock(
    session_state: Dict[str, Any],
    input_transcript: str,
    intent_name: str,
    use_bedrock: bool = True,
) -> Dict[str, Any]:
    """
    Fulfill the intent and/or answer the user: send to Bedrock with optional conversation
    history, then return the reply to Lex. Works for both Lex intents and general questions.
    """
    session_attrs = session_state.get("sessionAttributes") or {}
    history = _parse_history(session_attrs)
    # User message: include intent as context so Bedrock can tailor response
    user_message = input_transcript
    if intent_name and intent_name not in ("UnknownIntent", "FallbackIntent"):
        user_message = f"[Intent: {intent_name}] {input_transcript}"

    if use_bedrock:
        try:
            response_text = get_bedrock_response(
                user_message,
                intent_name,
                message_history=history if history else None,
            )
            # Persist history for next turn
            new_attrs = _save_history(session_attrs, user_message, response_text)
            return build_lex_response(
                session_state,
                response_text,
                intent_name,
                session_attributes_override=new_attrs,
            )
        except Exception as e:
            logger.exception("Bedrock invoke failed: %s", e)
            response_text = f"I couldn't generate a response right now. (Error: {e})"
    else:
        fallbacks = {
            "GreetingIntent": "Hello! How can I help you today?",
            "HelpIntent": "I'm here to help. What would you like to know?",
            "GoodbyeIntent": "Goodbye! Have a great day.",
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

        # Use proposedNextState.sessionState as base so Lex accepts our response (avoids fallback)
        proposed_next = event.get("proposedNextState", {})
        session_state = proposed_next.get("sessionState") or event.get("sessionState", {})
        intent = (session_state.get("intent") or proposed_next.get("intent") or {})
        intent_name = intent.get("name", "UnknownIntent")
        input_transcript = event.get("inputTranscript", "").strip() or "No input"
        use_bedrock = os.environ.get("USE_BEDROCK_FULFILLMENT", "true").lower() == "true"

        return fulfill_with_bedrock(
            session_state=session_state,
            input_transcript=input_transcript,
            intent_name=intent_name,
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
